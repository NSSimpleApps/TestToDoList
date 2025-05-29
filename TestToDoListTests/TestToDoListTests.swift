//
//  TestToDoListTests.swift
//  TestToDoListTests
//
//  Created by user on 29.05.2025.
//

import Foundation
import Testing
@testable import TestToDoList

let toDoCoreDataItemModel0 =
ToDoCoreDataItemModel(id: nil, title: "Title0",
                      itemDescription: "Description0",
                      completed: false, createdAt: Date())

let toDoCoreDataItemModel1 =
ToDoCoreDataItemModel(id: nil, title: "Title1",
                      itemDescription: "Description1",
                      completed: false, createdAt: toDoCoreDataItemModel0.createdAt.addingTimeInterval(1))

let toDoCoreDataItemModel2 =
ToDoCoreDataItemModel(id: nil, title: "Title2",
                      itemDescription: "Description2",
                      completed: false, createdAt: toDoCoreDataItemModel0.createdAt.addingTimeInterval(2))



struct TestToDoListCoreDataManager {
    let coreDataManager = CoreDataManager(coreDataConfiguration: ToDoStorageConfiguration())
    
    @Test func testCreate() async throws {
        let newToDoCoreDataItemModel = try await withCheckedThrowingContinuation { (checkedContinuation: CheckedContinuation<ToDoCoreDataItemModel, Error>) in
            self.coreDataManager.createManagedObject(ofType: ToDoCoreDataItem.self,
                                                     configureBlock: { toDoCoreDataItem in
                toDoCoreDataItemModel0.configure(managedObject: toDoCoreDataItem)
                return toDoCoreDataItemModel0
            },
                                                     completion: { result in
                if let result {
                    checkedContinuation.resume(with: result)
                } else {
                    checkedContinuation.resume(throwing: NSError.cancelledError(reason: "Cancelled"))
                }
            })
        }
        #expect(toDoCoreDataItemModel0 == newToDoCoreDataItemModel)
    }
    
    @Test func testDelete() async throws {
        let count = try await withCheckedThrowingContinuation { (checkedContinuation: CheckedContinuation<Int, Error>) in
            let predicate = NSPredicate(format: "%K == %@", #keyPath(ToDoCoreDataItem.id), toDoCoreDataItemModel0.id as NSObject)
            self.coreDataManager.deleteManagedObject(ofType: ToDoCoreDataItem.self,
                                                     predicate: predicate,
                                                     completion: { error in
                #expect(error == nil)
                let predicate = NSPredicate(format: "%K == %@", #keyPath(ToDoCoreDataItem.id), toDoCoreDataItemModel0.id as NSObject)
                self.coreDataManager.getModels(predicate: predicate, sortDescriptors: nil,
                                               convertBlock: { (toDoCoreDataItem: ToDoCoreDataItem) in
                    ToDoCoreDataItemModel(toDoCoreDataItem: toDoCoreDataItem)
                },
                                               completion: { result in
                    switch result {
                    case .success(let models):
                        checkedContinuation.resume(returning: models.count)
                    case .failure(let error):
                        checkedContinuation.resume(throwing: error)
                    default:
                        break
                    }
                })
            })
        }
        #expect(count == 0)
    }
    
    @Test func testSaveAndGet() async throws {
        let initialModels = [toDoCoreDataItemModel0, toDoCoreDataItemModel1, toDoCoreDataItemModel2]
        let newModels = try await withCheckedThrowingContinuation { (checkedContinuation: CheckedContinuation<[ToDoCoreDataItemModel], Error>) in
            self.coreDataManager.saveItems(items: initialModels, completion: { error in
                let predicate = NSPredicate(format: "%K IN %@", #keyPath(ToDoCoreDataItem.id), [toDoCoreDataItemModel0.id,
                                                                                                toDoCoreDataItemModel1.id,
                                                                                                toDoCoreDataItemModel2.id])
                let sortDescriptor = NSSortDescriptor(key: #keyPath(ToDoCoreDataItem.createdAt), ascending: true)
                self.coreDataManager.getModels(predicate: predicate, sortDescriptors: [sortDescriptor],
                                               convertBlock: { (toDoCoreDataItem: ToDoCoreDataItem) in
                    ToDoCoreDataItemModel(toDoCoreDataItem: toDoCoreDataItem)
                },
                                               completion: { result in
                    if let result {
                        checkedContinuation.resume(with: result)
                    } else {
                        checkedContinuation.resume(throwing: NSError.cancelledError(reason: "Cancelled"))
                    }
                })
            })
        }
        
        #expect(newModels == initialModels)
    }
    
    @Test func testUpdateModel() async throws {
        let newTitle = "NewTitle0"
        let newDescription = "NewDescription0"
        let newModel = try await withCheckedThrowingContinuation { (checkedContinuation: CheckedContinuation<ToDoCoreDataItemModel, Error>) in
            self.coreDataManager.saveItems(items: [toDoCoreDataItemModel0], completion: { error in
                let predicate = NSPredicate(format: "%K == %@", #keyPath(ToDoCoreDataItem.id), toDoCoreDataItemModel0.id as NSObject)
                
                self.coreDataManager.updateManagedObject(ofType: ToDoCoreDataItem.self, predicate: predicate,
                                                         updateBlock: { (toDoCoreDataItem: ToDoCoreDataItem) in
                    toDoCoreDataItem.title = newTitle
                    toDoCoreDataItem.itemDescription = newDescription
                    
                    return ToDoCoreDataItemModel(toDoCoreDataItem: toDoCoreDataItem)
                },
                                                         completion: { result in
                    if let result {
                        checkedContinuation.resume(with: result)
                    } else {
                        checkedContinuation.resume(throwing: NSError.cancelledError(reason: "Cancelled"))
                    }
                })
            })
        }
        #expect(newModel.title == newTitle)
        #expect(newModel.itemDescription == newDescription)
    }
}


struct TestToDoListDecodable {
    @Test func testDecodable() throws {
        let title = "Title"
        let completed = false
        
        let data = """
        {
        "todo": "\(title)",
        "completed": \(completed)
        }
        """.data(using: .utf8)!

        let toDoCoreDataItemDecodable0 = ToDoCoreDataItemDecodable(title: title, completed: completed)
        let toDoCoreDataItemDecodable1 = try JSONDecoder().decode(ToDoCoreDataItemDecodable.self, from: data)
        #expect(toDoCoreDataItemDecodable0 == toDoCoreDataItemDecodable1)
    }
}

struct TestToDoListDateFormat {
    @Test func testDate() {
        let now = Date()
        
        let toDoDateFormatter = ToDoDateFormatter(calendar: nil, dateFormats: [.HH, .colon, .mm, .space,
                                                                               .dd, .delim("/"),
                                                                               .MM, .delim("/"),
                                                                               .yyyy])
        let dateString = toDoDateFormatter.string(from: now)
        #expect(dateString == "12:00 29/05/2025")
    }
}
