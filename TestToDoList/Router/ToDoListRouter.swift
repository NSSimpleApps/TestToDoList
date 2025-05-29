//
//  ToDoListRouter.swift
//  TestToDoList
//
//  Created by user on 28.05.2025.
//


import Foundation
import UIKit

/// Создание экранов-модулей и навигация между ними.
@MainActor
protocol ToDoListRouterProtocol: Sendable {
    func createLoadingModule() -> UIViewController
    func createToDoListModule(comletion: @escaping @MainActor (UIViewController) -> Void)
    func createToDoDetailsModule(toDoListModel: ToDoListModel?, presenter: any ToDoListPresenterProtocol,
                                 todoListView: any TodoListViewProtocol) -> UIViewController
}

/// Создание экранов-модулей и навигация между ними.
final class ToDoListRouter: ToDoListRouterProtocol {
    @MainActor
    func createLoadingModule() -> UIViewController {
        return ToDoLoadingViewController()
    }
    
    func createToDoListModule(comletion: @escaping @MainActor (UIViewController) -> Void) {
        DispatchQueue.global().async {
            let toDoListHandler = ToDoListHandler(interactor: ToDoListDataProvider(), router: self)
            
            DispatchQueue.main.async {
                let navigationController = UINavigationController(rootViewController: ToDoListController(presenter: toDoListHandler))
                navigationController.navigationBar.prefersLargeTitles = true
                comletion(navigationController)
            }
        }
    }
    @MainActor
    func createToDoDetailsModule(toDoListModel: ToDoListModel?,
                                 presenter: any ToDoListPresenterProtocol,
                                 todoListView: any TodoListViewProtocol) -> UIViewController {
        let toDoListPreModel: ToDoListPreModelProtocol?
        if let toDoListModel {
            toDoListPreModel = ToDoCoreDataItemModel(id: toDoListModel.id,
                                                     title: toDoListModel.title.string,
                                                     itemDescription: toDoListModel.description,
                                                     completed: toDoListModel.completed,
                                                     createdAt: toDoListModel.createdAt)
        } else {
            toDoListPreModel = nil
        }
        return ToDoListDetailsController(toDoListPreModel: toDoListPreModel,
                                         eventBlock: { [weak presenter, weak todoListView] toDoListDetailsController, toDoListDetailsResult in
            guard let presenter, let todoListView else { return }
            
            toDoListDetailsController.navigationController?.popViewController(animated: true)
            
            switch toDoListDetailsResult {
            case .createOrUpdate(let toDoListDetailsNewModel):
                presenter.createOrUpdateToDoListModel(newModel: toDoListDetailsNewModel, todoListView: todoListView)
            case .delete(id: let id):
                presenter.deleteToDoListModel(withId: id, todoListView: todoListView)
            }
        })
    }
}
