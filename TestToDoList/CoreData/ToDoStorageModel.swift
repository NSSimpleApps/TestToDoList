//
//  ToDoStorageModel.swift
//  TestToDoList
//
//  Created by user on 27.05.2025.
//

import Foundation
import CoreData


/// Модель базы данных. Сейчас содержится только ToDoCoreDataItem.
struct ToDoStorageConfiguration: CoreDataConfiguration {
    var storageName: String {
        return "todo_list"
    }
    
    func currentModel() -> NSManagedObjectModel {
        return self.model0()
    }
    
    func model0() -> NSManagedObjectModel {
        let idAttribute = NSAttributeDescription()
        idAttribute.name = #keyPath(ToDoCoreDataItem.id)
        idAttribute.attributeType = .stringAttributeType
        idAttribute.isOptional = false
        
        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = #keyPath(ToDoCoreDataItem.title)
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false
        
        let itemDescriptionAttribute = NSAttributeDescription()
        itemDescriptionAttribute.name = #keyPath(ToDoCoreDataItem.itemDescription)
        itemDescriptionAttribute.attributeType = .stringAttributeType
        itemDescriptionAttribute.isOptional = true
        
        let completedAttribute = NSAttributeDescription()
        completedAttribute.name = #keyPath(ToDoCoreDataItem.completed)
        completedAttribute.attributeType = .booleanAttributeType
        completedAttribute.isOptional = false
        
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = #keyPath(ToDoCoreDataItem.createdAt)
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = false
        
        let toDoItemDescription = NSEntityDescription()
        toDoItemDescription.name = ToDoCoreDataItem.className()
        toDoItemDescription.managedObjectClassName = toDoItemDescription.name
        toDoItemDescription.properties = [idAttribute, titleAttribute, itemDescriptionAttribute, completedAttribute, createdAtAttribute]
        
        let model = NSManagedObjectModel()
        model.versionIdentifiers = [0]
        model.entities = [toDoItemDescription]
        
        return model
    }
    
    func migrationManager(forOldVersion: Int) throws(NSError) -> CoreDataMigrationManager {
        throw NSError(code: -1, reason: "Пока мигрировать нечего.")
    }
}

