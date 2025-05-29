//
//  ToDoListDataProvider.swift
//  TestToDoList
//
//  Created by user on 27.05.2025.
//

import Foundation

/// Взаимодействие с внешним источником данных или базой
/// а так же сохрание и обновление элементов.
protocol ToDoListInteractorProtocol: AnyObject {
    func getItems(ignoreCache: Bool, searchString: String?,
                  completion: @escaping @Sendable (Result<[ToDoListPreModelProtocol], NSError>?) -> Void)
    func deleteItem(id: String, completion: @escaping @Sendable (NSError?) -> Void)
    func updateItem(id: String, newTitle: String, newDescription: String?, newCompleted: Bool,
                    completion: @escaping @Sendable (Result<ToDoListPreModelProtocol, NSError>?) -> Void)
    func createItem(newTitle: String, newDescription: String?, newCompleted: Bool,
                    completion: @escaping @Sendable (Result<ToDoListPreModelProtocol, NSError>?) -> Void)
}


/// JSON-данные от бакенда.
struct ToDoListContainer: Decodable {
    let todos: [ToDoCoreDataItemDecodable]
    
    func createdAtArray(count: Int) -> [Date] {
        if count == 0 {
            return []
        } else {
            let now = Date()
            if count == 1 {
                return [now]
            } else {
                let timeInterval: TimeInterval = 24 * 60 * 60
                
                return (0..<count).map { step in
                    now.addingTimeInterval(-TimeInterval(step) * timeInterval / TimeInterval(count - 1))
                }
            }
        }
    }
}

/// Загружает, сохраняет и считывает данные. Взаимодействует с бакендом и базой данных.
final class ToDoListDataProvider: ToDoListInteractorProtocol {
    private let coreDataManager = CoreDataManager(coreDataConfiguration: ToDoStorageConfiguration())
    private let toDoListNetworkProvider = ToDoListNetworkProvider()
    
    func getItems(ignoreCache: Bool, searchString: String?,
                  completion: @escaping @Sendable (Result<[any ToDoListPreModelProtocol], NSError>?) -> Void) {
        let coreDataManager = self.coreDataManager
        
        if ignoreCache {
            self.toDoListNetworkProvider.loadToDoList(completion: { result in
                switch result {
                case .success(let data):
                    do {
                        let toDoListContainer = try JSONDecoder().decode(ToDoListContainer.self, from: data)
                        let todos = toDoListContainer.todos
                        let createdAtArray = toDoListContainer.createdAtArray(count: todos.count)
                        let toDoList = todos.enumerated().map { (index, toDoCoreDataItemDecodable) in
                            ToDoCoreDataItemModel(toDoCoreDataItemDecodable: toDoCoreDataItemDecodable, createdAt: createdAtArray[index])
                        }
                        coreDataManager.saveItems(items: toDoList, completion: { error in
                            if let error {
                                print(error)
                            }
                        })
                        if let searchString {
                            let filteredToDoList = toDoList.filter { toDoCoreDataItemModel in
                                if toDoCoreDataItemModel.title.localizedCaseInsensitiveContains(searchString) {
                                    return true
                                } else if let itemDescription = toDoCoreDataItemModel.itemDescription {
                                    return itemDescription.localizedCaseInsensitiveContains(searchString)
                                } else {
                                    return false
                                }
                            }
                            completion(.success(filteredToDoList))
                        } else {
                            completion(.success(toDoList))
                        }
                    } catch {
                        completion(.failure(error as NSError))
                    }
                case .failure(let error):
                    if error.isCancelled {
                        completion(nil)
                    } else {
                        completion(.failure(error))
                    }
                }
            })
        } else {
            let sortDescriptor = NSSortDescriptor(key: #keyPath(ToDoCoreDataItem.createdAt), ascending: false)
            let predicate: NSPredicate?
            if let searchString {
                let titlePredicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(ToDoCoreDataItem.title), searchString)
                let descriptionPredicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(ToDoCoreDataItem.itemDescription), searchString)
                predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, descriptionPredicate])
            } else {
                predicate = nil
            }
            self.coreDataManager.getModels(predicate: predicate, sortDescriptors: [sortDescriptor],
                                           convertBlock: { (toDoCoreDataItem: ToDoCoreDataItem) in
                ToDoCoreDataItemModel(toDoCoreDataItem: toDoCoreDataItem)
            },
                                           completion: completion)
        }
    }
    func deleteItem(id: String, completion: @escaping @Sendable (NSError?) -> Void) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(ToDoCoreDataItem.id), id as NSObject)
        self.coreDataManager.deleteManagedObject(ofType: ToDoCoreDataItem.self, predicate: predicate, completion: completion)
    }
    
    func updateItem(id: String, newTitle: String, newDescription: String?, newCompleted: Bool,
                    completion: @escaping @Sendable (Result<any ToDoListPreModelProtocol, NSError>?) -> Void) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(ToDoCoreDataItem.id), id as NSObject)
        self.coreDataManager.updateManagedObject(ofType: ToDoCoreDataItem.self,
                                                 predicate: predicate,
                                                 updateBlock: { (toDoCoreDataItem: ToDoCoreDataItem) in
            toDoCoreDataItem.title = newTitle
            toDoCoreDataItem.itemDescription = newDescription
            toDoCoreDataItem.completed = newCompleted
            
            return ToDoCoreDataItemModel(toDoCoreDataItem: toDoCoreDataItem)
        },
                                                 completion: completion)
    }
    
    func createItem(newTitle: String, newDescription: String?, newCompleted: Bool, completion: @escaping @Sendable (Result<any ToDoListPreModelProtocol, NSError>?) -> Void) {
        self.coreDataManager.createManagedObject(ofType: ToDoCoreDataItem.self,
                                                 configureBlock: { (toDoCoreDataItem: ToDoCoreDataItem) in
            let toDoCoreDataItemModel =
            ToDoCoreDataItemModel(id: nil, title: newTitle,
                                  itemDescription: newDescription, completed: newCompleted, createdAt: Date())
            toDoCoreDataItemModel.configure(managedObject: toDoCoreDataItem)
            
            return toDoCoreDataItemModel
        },
                                                 completion: completion)
    }
}
