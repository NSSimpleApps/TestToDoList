//
//  ToDoListHandler.swift
//  TestToDoList
//
//  Created by user on 27.05.2025.
//


import Foundation
import UIKit

/// Протокол для взаимодейстия presenter<->view.
protocol ToDoListPresenterProtocol: AnyObject {
    func loadToDoListModels(ignoreCache: Bool, searchString: String?, todoListView: TodoListViewProtocol)
    func displayToDoListModel(toDoListModel: ToDoListModel?, todoListView: TodoListViewProtocol)
    
    func shareToDoListModel(toDoListModel: ToDoListModel, todoListView: TodoListViewProtocol)
    func deleteToDoListModel(withId id: String, todoListView: TodoListViewProtocol)
    
    func createOrUpdateToDoListModel(newModel: ToDoListDetailsNewModel, todoListView: TodoListViewProtocol)
    
    func cancelAllOperations()
}

/// Протокол для модели, которая получается из базы.
protocol ToDoListPreModelProtocol: Sendable {
    var id: String { get }
    var title: String { get }
    var itemDescription: String? { get }
    var createdAt: Date { get }
    var completed: Bool { get }
}

/// Получение и предобработка данных из внешнего источника,
/// а также обработка пользовательских событий от View.
final class ToDoListHandler: @preconcurrency ToDoListPresenterProtocol {
    private let router: ToDoListRouterProtocol
    private let interactor: ToDoListInteractorProtocol
    private let operationQueue = OperationQueue(name: "ToDoListHandler")
    private let dateFormatter = ToDoDateFormatter(calendar: nil, dateFormats: [.HH, .colon, .mm, .space,
                                                                               .dd, .delim("/"),
                                                                               .MM, .delim("/"),
                                                                               .yyyy])
    
    init(interactor: any ToDoListInteractorProtocol, router: any ToDoListRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }
    
    func loadToDoListModels(ignoreCache: Bool, searchString: String?, todoListView: any TodoListViewProtocol) {
        let interactor = self.interactor
        let dateFormatter = self.dateFormatter
        
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            let hasToDoListSavedKey = "com.todolist.hasToDoListSaved"
            let ignoreCacheValue: Bool
            if ignoreCache {
                ignoreCacheValue = true
            } else {
                let hasToDoListSaved = UserDefaults.standard.bool(forKey: hasToDoListSavedKey)
                ignoreCacheValue = hasToDoListSaved == false
            }
            interactor.getItems(ignoreCache: ignoreCacheValue, searchString: searchString, completion: { result in
                if asyncOperation.isCancelled {
                    return
                }
                switch result {
                case .success(let toDoPreModels):
                    UserDefaults.standard.set(true, forKey: hasToDoListSavedKey)
                    
                    let toDoModels = toDoPreModels.map { toDoPreModel in
                        return ToDoListModel(toDoPreModel: toDoPreModel, toDoDateFormatter: dateFormatter)
                    }
                    asyncOperation.finish(with: .success(toDoModels))
                case .failure(let error):
                    if error.isCancelled {
                        asyncOperation.cancel()
                    } else {
                        asyncOperation.finish(with: .failure(error))
                    }
                default:
                    asyncOperation.cancel()
                }
            })
            return .await
        },
                                completion: { [weak todoListView] (result: Result<[ToDoListModel], NSError>?) in
            guard let todoListView else { return }
            
            switch result {
            case .success(let toDoListModels):
                DispatchQueue.main.async {
                    todoListView.display(toDoListModels: toDoListModels)
                }
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    todoListView.displayError()
                }
            default:
                break
            }
        })
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
    
    @MainActor
    func displayToDoListModel(toDoListModel: ToDoListModel?, todoListView: any TodoListViewProtocol) {
        let toDoDetailsModule = self.router.createToDoDetailsModule(toDoListModel: toDoListModel,
                                                                    presenter: self, todoListView: todoListView)
        todoListView.navigationController?.pushViewController(toDoDetailsModule, animated: true)
    }
    
    @MainActor
    func shareToDoListModel(toDoListModel: ToDoListModel, todoListView: TodoListViewProtocol) {
        let activityViewController = UIActivityViewController(activityItems: [toDoListModel.title.string],
                                                              applicationActivities: nil)
        todoListView.present(activityViewController, animated: true)
    }
    
    @MainActor
    func deleteToDoListModel(withId id: String, todoListView: any TodoListViewProtocol) {
        let interactor = self.interactor
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            interactor.deleteItem(id: id,
                                  completion: { error in
                if asyncOperation.isCancelled {
                    return
                }
                
                if let error {
                    if error.isCancelled {
                        asyncOperation.cancel()
                    } else {
                        asyncOperation.finish(with: .failure(error))
                    }
                } else {
                    asyncOperation.finish(with: .success(()))
                }
            })
            return .await
        }, completion: { [weak todoListView] (result: Result<Void, NSError>?) in
            guard let todoListView else { return }
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    todoListView.deleteToDoListModel(withId: id)
                }
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    todoListView.displayError()
                }
            default:
                break
            }
        })
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
    
    func createOrUpdateToDoListModel(newModel: ToDoListDetailsNewModel, todoListView: any TodoListViewProtocol) {
        let interactor = self.interactor
        let dateFormatter = self.dateFormatter
        let shouldUpdate = newModel.id != nil
        
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            let newTitle = newModel.title
            let newDescription = newModel.description
            let newCompleted = newModel.completed
            let commonCompletion: @Sendable (Result<ToDoListPreModelProtocol, NSError>?) -> Void = { result in
                if asyncOperation.isCancelled {
                    return
                }
                switch result {
                case .success(let toDoListPreModelProtocol):
                    asyncOperation.finish(with: .success(toDoListPreModelProtocol))
                case .failure(let error):
                    if error.isCancelled {
                        asyncOperation.cancel()
                    } else {
                        asyncOperation.finish(with: .failure(error))
                    }
                default:
                    asyncOperation.cancel()
                }
            }
            if let id = newModel.id {
                interactor.updateItem(id: id, newTitle: newTitle,
                                      newDescription: newDescription, newCompleted: newCompleted,
                                      completion: commonCompletion)
            } else {
                interactor.createItem(newTitle: newTitle, newDescription: newDescription,
                                      newCompleted: newCompleted,
                                      completion: commonCompletion)
            }
            return .await
        }, completion: { [weak todoListView] (result: Result<ToDoListPreModelProtocol, NSError>?) in
            guard let todoListView else { return }
            
            switch result {
            case .success(let toDoListPreModel):
                let toDoListModel = ToDoListModel(toDoPreModel: toDoListPreModel, toDoDateFormatter: dateFormatter)
                DispatchQueue.main.async {
                    if shouldUpdate {
                        todoListView.update(toDoListModel: toDoListModel)
                    } else {
                        todoListView.insert(toDoListModel: toDoListModel)
                    }
                }
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    todoListView.displayError()
                }
            default:
                break
            }
        })
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
    
    func cancelAllOperations() {
        self.operationQueue.cancelAllOperations()
    }
    deinit {
        self.cancelAllOperations()
    }
}
