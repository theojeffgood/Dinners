//
//  DataController.swift
//  FryDay
//
//  Created by Theo Goodman on 2/16/23.
//

import CoreData
import CloudKit

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
        
        guard let privateStoreDescription = container.persistentStoreDescriptions.first else {
            fatalError("Unable to get persistentStoreDescription")
        }
        let storesURL = privateStoreDescription.url?.deletingLastPathComponent()
        privateStoreDescription.url = storesURL?.appendingPathComponent("private.sqlite")
        let sharedStoreURL = storesURL?.appendingPathComponent("shared.sqlite")
        guard let sharedStoreDescription = privateStoreDescription.copy() as? NSPersistentStoreDescription else {
            fatalError("Copying the private store description returned an unexpected value.")
        }
        sharedStoreDescription.url = sharedStoreURL
        
        guard let containerIdentifier = privateStoreDescription.cloudKitContainerOptions?.containerIdentifier else {
            fatalError("Unable to get containerIdentifier")
        }
        let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
        sharedStoreOptions.databaseScope = .shared
        sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions
        container.persistentStoreDescriptions.append(sharedStoreDescription)
        
        container.loadPersistentStores { loadedStoreDescription, error in
            if let error = error as NSError? {
                fatalError("Failed to load persistent stores: \(error)")
            } else if let cloudKitContainerOptions = loadedStoreDescription.cloudKitContainerOptions {
                guard let loadedStoreDescritionURL = loadedStoreDescription.url else {
                    return
                }
                
                if cloudKitContainerOptions.databaseScope == .private {
                    let privateStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescritionURL)
                    self._privatePersistentStore = privateStore
                } else if cloudKitContainerOptions.databaseScope == .shared {
                    let sharedStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescritionURL)
                    self._sharedPersistentStore = sharedStore
                }
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
    private init() {}
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
    
    func delete(_ recipe: Recipe) {
        context.perform {
            self.context.delete(recipe)
            self.save()
        }
    }
}

// MARK: -- Share a record from Core Data
extension DataController {
    func isShared(object: NSManagedObject) -> Bool {
        isShared(objectID: object.objectID)
    }
    
    func canEdit(object: NSManagedObject) -> Bool {
        return persistentContainer.canUpdateRecord(forManagedObjectWith: object.objectID)
    }
    
    func canDelete(object: NSManagedObject) -> Bool {
        return persistentContainer.canDeleteRecord(forManagedObjectWith: object.objectID)
    }
    
    func isOwner(object: NSManagedObject) -> Bool {
        guard isShared(object: object) else { return false }
        guard let share = try? persistentContainer.fetchShares(matching: [object.objectID])[object.objectID] else {
            print("Get ckshare error")
            return false
        }
        if let currentUser = share.currentUserParticipant, currentUser == share.owner {
            return true
        }
        return false
    }
    
    func getShare(_ recipe: Recipe) -> CKShare? {
        guard isShared(object: recipe) else { return nil }
        guard let shareDictionary = try? persistentContainer.fetchShares(matching: [recipe.objectID]),
              let share = shareDictionary[recipe.objectID] else {
            print("Unable to get CKShare")
            return nil
        }
        share[CKShare.SystemFieldKey.title] = recipe.title
        
        return share
    }
    
    private func isShared(objectID: NSManagedObjectID) -> Bool {
        var isShared = false
        if let persistentStore = objectID.persistentStore {
            if persistentStore == sharedPersistentStore {
                isShared = true
            } else {
                let container = persistentContainer
                do {
                    let shares = try container.fetchShares(matching: [objectID])
                    if shares.first != nil {
                        isShared = true
                    }
                } catch {
                    print("Failed to fetch share for \(objectID): \(error)")
                }
            }
        }
        return isShared
    }
}


//class DataController: ObservableObject {
//    
//    let container = NSPersistentCloudKitContainer(name: "MealSwipe")
//    
//    init() {
//        container.loadPersistentStores { description, error in
//            print("description: \(description.options)")
//            if let error{
//                print("Core Data failed to load: \(error.localizedDescription)")
//            }
//        }
//        
//        // Only initialize the schema when building the app with the
//        // Debug build configuration.
//        #if DEBUG
//        do {
//            // Use the container to initialize the development schema.
//            try container.initializeCloudKitSchema(options: [])
//        } catch {
//            // Handle any errors.
//        }
//        #endif
//        
////        SAVE CHANGES WHEN APP GOES TO BACKGROUND: https://www.donnywals.com/using-core-data-with-swiftui-2-0-and-xcode-12/
////        let center = NotificationCenter.default
////        let notification = UIApplication.willResignActiveNotification
////
////        center.addObserver(forName: notification, object: nil, queue: nil) { [weak self] _ in
////            guard let self = self else { return }
////
////            if self.container.viewContext.hasChanges {
////                try? self.container.viewContext.save()
////            }
////        }
//    }
//}
