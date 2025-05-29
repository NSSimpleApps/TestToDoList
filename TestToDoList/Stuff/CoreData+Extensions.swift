//
//  CoreData+Extensions.swift
//  TestToDoList
//
//  Created by user on 27.05.2025.
//


import Foundation
import CoreData

extension NSManagedObject {
    /// Имя класса для хранимого объекта.
    static func className() -> String {
        return String(describing: self.self)
    }
}
extension NSManagedObjectModel {
    /// Номер версии базы данных.
    var versionIdentifier: Int? {
        return self.versionIdentifiers.first as? Int
    }
}
extension NSPersistentStoreCoordinator {
    /// Номер версии файла базы данных.
    static func storeVersion(type storeType: NSPersistentStore.StoreType, at storeURL: URL) throws(NSError) -> Int? {
        do {
            let metadataForPersistentStore = try self.metadataForPersistentStore(type: storeType, at: storeURL)
            let versions = metadataForPersistentStore[NSStoreModelVersionIdentifiersKey] as? [Int]
            return versions?.first
        } catch {
            let catchedError = error as NSError
            if catchedError.code == NSFileReadNoSuchFileError {
                return nil
            } else {
                throw catchedError
            }
        }
    }
    /// Удаление хранилища.
    func _destroyPersistentStore(at url: URL, type: NSPersistentStore.StoreType) throws(NSError) {
        do {
            try self.destroyPersistentStore(at: url, type: type)
        } catch {
            throw error as NSError
        }
    }
    /// Перемещение хранилища.
    func _replacePersistentStore(at destinationURL: URL, withPersistentStoreFrom sourceURL: URL,
                                 type: NSPersistentStore.StoreType) throws(NSError) {
        do {
            try self.replacePersistentStore(at: destinationURL, withPersistentStoreFrom: sourceURL,
                                            type: type)
        } catch {
            throw error as NSError
        }
    }
}

extension NSMigrationManager {
    /// Миграция базы данных.
    func migrateStore(from sourceURL: URL, to destinationURL: URL,
                      mapping: NSMappingModel,
                      storeType: NSPersistentStore.StoreType) throws(NSError) {
        do {
            try self.migrateStore(from: sourceURL, type: storeType, mapping: mapping,
                                  to: destinationURL, type: storeType)
        } catch {
            throw error as NSError
        }
    }
}


extension FileManager {
    func safeRemoveItem(at URL: URL) {
        do {
            try self.removeItem(at: URL)
        } catch let error as NSError {
            if error.code == NSFileNoSuchFileError {
                return
            } else {
                print(error)
            }
        }
    }
}
