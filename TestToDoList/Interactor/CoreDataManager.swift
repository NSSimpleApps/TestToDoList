//
//  CoreDataManager.swift
//  TestToDoList
//
//  Created by user on 26.05.2025.
//


import Foundation
import CoreData

/// Протокол для конфигурации CoreData.
/// Имя хранилища, текущая модель, обновление базы со старой версии.
protocol CoreDataConfiguration {
    var storageName: String { get }
    func currentModel() -> NSManagedObjectModel
    func migrationManager(forOldVersion: Int) throws(NSError) -> CoreDataMigrationManager
}
/// Обновление базы со старой версии.
struct CoreDataMigrationManager {
    let mappingModel: NSMappingModel
    let migrationManager: NSMigrationManager
}
/// Протокол для сохранения данных в базу из стороннего объекта.
protocol PreManagedObjectProtocol: Sendable {
    associatedtype ManagedObject: NSManagedObject
    func configure(managedObject: ManagedObject)
}

/// Управление CoreData.
/// Гарантирует последовательный доступ к управляемому хранилищу.
final class CoreDataManager: Sendable {
    private let operationQueue = OperationQueue(name: "CoreDataManager")
    private let persistentContainer: NSPersistentContainer
    
    init(coreDataConfiguration: CoreDataConfiguration) {
        let currentModel = coreDataConfiguration.currentModel()
        let currentVersion = currentModel.versionIdentifier
        let persistentContainer = NSPersistentContainer(name: coreDataConfiguration.storageName,
                                                        managedObjectModel: currentModel)
        self.persistentContainer = persistentContainer
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
            
            for persistentStoreDescription in persistentContainer.persistentStoreDescriptions {
                let storeType = NSPersistentStore.StoreType(rawValue: persistentStoreDescription.type)
                if let sourceUrl = persistentStoreDescription.url,
                   let currentVersion,
                   let storeVersion = try NSPersistentStoreCoordinator.storeVersion(type: storeType, at: sourceUrl) {
                    if storeVersion > currentVersion {
                        try persistentStoreCoordinator._destroyPersistentStore(at: sourceUrl, type: storeType)
                    }
                    let destinationURL = sourceUrl.appendingPathExtension("tmp")
                    
                    for version in storeVersion..<currentVersion {
                        let coreDataMigrationManager = try coreDataConfiguration.migrationManager(forOldVersion: version)
                        print("MIGRATE FROM:", storeVersion, "TO: ", version)
                        let migrationManager = coreDataMigrationManager.migrationManager
                        try migrationManager.migrateStore(from: sourceUrl, to: destinationURL, mapping: migrationManager.mappingModel,
                                                          storeType: storeType)
                        try persistentStoreCoordinator._replacePersistentStore(at: sourceUrl,
                                                                               withPersistentStoreFrom: destinationURL,
                                                                               type: storeType)
                        try persistentStoreCoordinator._destroyPersistentStore(at: destinationURL, type: storeType)
                        FileManager.default.safeRemoveItem(at: destinationURL)
                    }
                }
            }
            
            persistentContainer.loadPersistentStores(completionHandler: { persistentStoreDescription, error in
                if let error {
                    asyncOperation.finish(with: .failure(error as NSError))
                } else {
                    asyncOperation.finish(with: .success(persistentStoreDescription.type))
                }
            })
            return .await
        },
                                completion: { (result: Result<String, NSError>?) in
            switch result {
            case .success(let storeType):
                print("LOADING DATABASE FINISHED WITH TYPE:", storeType)
            case .failure(let error):
                print("LOADING DATABASE FINISHED WITH ERROR:", error)
            default:
                break
            }
        })
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
    
    func getModels<ManagedObject: NSManagedObject, Model>(predicate: NSPredicate?,
                                                          sortDescriptors: [NSSortDescriptor]?,
                                                          convertBlock: @escaping (ManagedObject) -> Model,
                                                          completion: @escaping @Sendable (Result<[Model], NSError>?) -> Void) {
        let persistentContainer = self.persistentContainer
        
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            let managedObjectContext = persistentContainer.newBackgroundContext()
            let fetchRequest = NSFetchRequest<ManagedObject>(entityName: ManagedObject.className())
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = sortDescriptors
            do {
                let models = try managedObjectContext.fetch(fetchRequest).map { managedObject in
                    convertBlock(managedObject)
                }
                return .success(models)
            } catch {
                throw error as NSError
            }
        },
                                completion: completion)
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
    
    func saveItems<PreManagedObject: PreManagedObjectProtocol>(items: any Collection<PreManagedObject>,
                                                               completion: @escaping @Sendable (NSError?) -> Void) {
        let persistentContainer = self.persistentContainer
        
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            do {
                let entityName = PreManagedObject.ManagedObject.className()
                let managedObjectContext = persistentContainer.newBackgroundContext()
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: managedObjectContext)
                
                for item in items {
                    let managedObject = PreManagedObject.ManagedObject(context: managedObjectContext)
                    item.configure(managedObject: managedObject)
                }
                try managedObjectContext.save()
                return .success(())
            } catch {
                throw error as NSError
            }
        },
                                completion: { (result: Result<Void, NSError>?) in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            default:
                break
            }
        })
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
    
    func deleteManagedObject<ManagedObject: NSManagedObject>(ofType itemType: ManagedObject.Type,
                                                             predicate: NSPredicate,
                                                             completion: @escaping @Sendable (NSError?) -> Void) {
        let persistentContainer = self.persistentContainer
        
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            do {
                let entityName = itemType.className()
                let managedObjectContext = persistentContainer.newBackgroundContext()
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                fetchRequest.predicate = predicate
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: managedObjectContext)
                try managedObjectContext.save()
                
                return .success(())
            } catch {
                throw error as NSError
            }
        },
                                completion: { (result: Result<Void, NSError>?) in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            default:
                break
            }
        })
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
    
    func updateManagedObject<ManagedObject: NSManagedObject, Model>(ofType itemType: ManagedObject.Type,
                                                                    predicate: NSPredicate,
                                                                    updateBlock: @escaping @Sendable (ManagedObject) -> Model,
                                                                    completion: @escaping @Sendable (Result<Model, NSError>?) -> Void) {
        let persistentContainer = self.persistentContainer
        
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            do {
                let entityName = itemType.className()
                let managedObjectContext = persistentContainer.newBackgroundContext()
                let fetchRequest = NSFetchRequest<ManagedObject>(entityName: entityName)
                fetchRequest.predicate = predicate
                
                if let managedObject = try managedObjectContext.fetch(fetchRequest).first {
                    let model = updateBlock(managedObject)
                    try managedObjectContext.save()
                    
                    return .success(model)
                } else {
                    throw NSError(code: -1, reason: "Item not found.")
                }
            } catch {
                throw error as NSError
            }
        },
                                completion: { (result: Result<Model, NSError>?) in
            if let result {
                completion(result)
            } else {
                completion(nil)
            }
        })
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
    
    func createManagedObject<ManagedObject: NSManagedObject, Model>(ofType itemType: ManagedObject.Type,
                                                                    configureBlock: @escaping @Sendable (ManagedObject) -> Model,
                                                                    completion: @escaping @Sendable (Result<Model, NSError>?) -> Void) {
        let persistentContainer = self.persistentContainer
        
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            do {
                let managedObjectContext = persistentContainer.newBackgroundContext()
                let managedObject = ManagedObject(context: managedObjectContext)
                let model = configureBlock(managedObject)
                try managedObjectContext.save()
                return .success(model)
            } catch {
                throw error as NSError
            }
        },
                                completion: { (result: Result<Model, NSError>?) in
            if let result {
                completion(result)
            } else {
                completion(nil)
            }
        })
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
}
