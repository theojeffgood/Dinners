//
//  DataController.swift
//  FryDay
//
//  Created by Theo Goodman on 2/16/23.
//

import CoreData
import CloudKit
import SwiftUI

final class DataController: ObservableObject {
    static let shared = DataController()
    
    var ckContainer: CKContainer {
        let storeDescription = persistentContainer.persistentStoreDescriptions.first
        guard let identifier = storeDescription?.cloudKitContainerOptions?.containerIdentifier else {
            fatalError("Unable to get container identifier")
        }
        return CKContainer(identifier: identifier)
    }
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    var privatePersistentStore: NSPersistentStore {
        guard let privateStore = _privatePersistentStore else {
            fatalError("Private store is not set")
        }
        return privateStore
    }
    
    var sharedPersistentStore: NSPersistentStore {
        guard let sharedStore = _sharedPersistentStore else {
            fatalError("Shared store is not set")
        }
        return sharedStore
    }
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "MealSwipe")
        
        guard let privateStoreDescription = container.persistentStoreDescriptions.first,
              let sharedStoreDescription = privateStoreDescription.copy() as? NSPersistentStoreDescription 
        else { fatalError("storeDescriptions failed.") }
        
        let storeURL = privateStoreDescription.url?.deletingLastPathComponent()
        sharedStoreDescription.url = storeURL?.appendingPathComponent("shared.sqlite")
        privateStoreDescription.url  = storeURL?.appendingPathComponent("private.sqlite")
        
        guard let containerId = privateStoreDescription.cloudKitContainerOptions?.containerIdentifier else { fatalError("containerIdentifier failed.") }
        let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerId)
        sharedStoreOptions.databaseScope = .shared
        sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions
        
        container.persistentStoreDescriptions.append(sharedStoreDescription)
        container.loadPersistentStores { loadedStoreDescription, error in
            if let error = error as NSError? { fatalError("Core Data failed to load: \(error)") }
            
            guard let ckContainerOptions = loadedStoreDescription.cloudKitContainerOptions,
                  let storeDescriptionURL = loadedStoreDescription.url else { return }
            
            if ckContainerOptions.databaseScope == .private {
                let privateStore = container.persistentStoreCoordinator.persistentStore(for: storeDescriptionURL)
                self._privatePersistentStore = privateStore
            } else if ckContainerOptions.databaseScope == .shared {
                let sharedStore = container.persistentStoreCoordinator.persistentStore(for: storeDescriptionURL)
                self._sharedPersistentStore = sharedStore
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Failed to pin viewContext to the current generation: \(error)")
        }
        
        return container
    }()
    
    private var _privatePersistentStore: NSPersistentStore?
    private var _sharedPersistentStore: NSPersistentStore?
    
//    SAVE CHANGES WHEN APP GOES TO BACKGROUND: www.donnywals.com/using-core-data-with-swiftui-2-0-and-xcode-12/
    private init() {
        let center = NotificationCenter.default
        let notification = UIApplication.willResignActiveNotification

        center.addObserver(forName: notification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }

            if self.context.hasChanges {
                try? self.context.save()
            }
        }
    }
}

// MARK: Save or delete from Core Data
extension DataController {
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("ViewContext save error: \(error)")
            }
        }
    }
    
//    func delete(_ recipe: Recipe) {
//        context.perform {
//            self.context.delete(recipe)
//            self.save()
//        }
//    }
}

extension NSManagedObject{
    func assignToCorrectStore(){
        let stack = DataController.shared
        let store = (UserDefaults.standard.bool(forKey: "inAHousehold") && !UserDefaults.standard.bool(forKey: "isHouseholdOwner")) ?
        stack.privatePersistentStore : stack.sharedPersistentStore
        stack.persistentContainer.viewContext.assign(self, to: store)
    }
    
    func assignToPrivateStore(){
        let stack = DataController.shared
        stack.persistentContainer.viewContext.assign(self, to: stack.privatePersistentStore)
    }
}
