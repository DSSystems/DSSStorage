//
//  DSSCoreDataManager.swift
//  DSSStorage
//
//  Created by David on 13/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import CoreData

final public class DSSCoreDataManager {
    private let modelName: String
    
    private let bundle: Bundle?
    
    private(set) lazy var managedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
    }()
    
    public var context: NSManagedObjectContext { managedObjectContext }
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let bundle = self.bundle ?? Bundle(for: type(of: self))
        
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd") else {
            fatalError("Unable to Find Data Model")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to Load Data Model")
        }

        return managedObjectModel
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let fileManager = FileManager.default
        let storeName = "\(self.modelName).sqlite"
        
        guard let applicationSupportDirectoryURL = try? fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
        )
        else {
            fatalError("\(#file) \(#function) \(#line): Unable to get 'Application Support' directory")
        }
        
        let persistentStoreURL = applicationSupportDirectoryURL.appendingPathComponent(storeName)

        do {
            try persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: persistentStoreURL,
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
        } catch {
            fatalError("\(#file) \(#function) \(#line): Unable to load persistent store: \(error.localizedDescription)")
        }
        return persistentStoreCoordinator
    }()
    
    public init(modelName: String, bundle: Bundle?) {
        self.bundle = bundle
        self.modelName = modelName
    }
}
