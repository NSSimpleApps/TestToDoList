//
//  ToDoCoreDataItem.swift
//  TestToDoList
//
//  Created by user on 27.05.2025.
//


import Foundation
import CoreData


/// Задача, которая хранится в базе данных.
@objc(ToDoCoreDataItem)
final class ToDoCoreDataItem: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var title: String
    @NSManaged var itemDescription: String?
    @NSManaged var completed: Bool
    @NSManaged var createdAt: Date
}

/// Модель, которая конфигурирует задачу для базы данных
/// или создаёт себя из задачи, чтобы не таскать объект NSManagedObject.
struct ToDoCoreDataItemModel: ToDoListPreModelProtocol, PreManagedObjectProtocol, Equatable {
    typealias ManagedObject = ToDoCoreDataItem
    
    let id: String
    let title: String
    let itemDescription: String?
    let completed: Bool
    let createdAt: Date
    
    init(toDoCoreDataItemDecodable: ToDoCoreDataItemDecodable, createdAt: Date) {
        let title = toDoCoreDataItemDecodable.title
        let itemDescription: String?
        
        if Bool.random() {
            itemDescription = title
        } else {
            itemDescription = nil
        }
        self.init(id: nil,
                  title: title,
                  itemDescription: itemDescription,
                  completed: toDoCoreDataItemDecodable.completed,
                  createdAt: createdAt)
    }
    init(toDoCoreDataItem: ToDoCoreDataItem) {
        self.init(id: toDoCoreDataItem.id,
                  title: toDoCoreDataItem.title,
                  itemDescription: toDoCoreDataItem.itemDescription,
                  completed: toDoCoreDataItem.completed,
                  createdAt: toDoCoreDataItem.createdAt)
    }
    init(id: String?, title: String, itemDescription: String?,
         completed: Bool, createdAt: Date) {
        self.id = id ?? UUID().uuidString
        self.title = title
        self.itemDescription = itemDescription
        self.completed = completed
        self.createdAt = createdAt
    }
    
    func configure(managedObject: ToDoCoreDataItem) {
        managedObject.id = self.id
        managedObject.title = self.title
        managedObject.itemDescription = self.itemDescription
        managedObject.completed = self.completed
        managedObject.createdAt = self.createdAt
    }
}

/// Задача, которую возвращает бакенд.
/// Поддерживает json-декодинг.
struct ToDoCoreDataItemDecodable: Decodable, Equatable {
    enum CodingKeys: String, CodingKey {
        case title = "todo"
        case completed
    }
    let title: String
    let completed: Bool
}
