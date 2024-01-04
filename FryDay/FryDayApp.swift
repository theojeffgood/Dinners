//
//  FryDayApp.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI
import CloudKit
import CoreData

@main
struct FryDayApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // necessary to fire scene delegate. accept share invitates.
    @StateObject var recipeManager: RecipeManager
    
    @StateObject
        private var purchaseManager: PurchaseManager
    
    init() {
        let purchaseManager = PurchaseManager()
        self._purchaseManager = StateObject(wrappedValue: purchaseManager)
        
        if UserDefaults.standard.string(forKey: "userID") == nil {
            let userId: String = "\(UUID())"
            UserDefaults.standard.set(userId, forKey: "userID")
        }
        
        let storage = RecipeManager(managedObjectContext: DataController.shared.context)
        self._recipeManager = StateObject(wrappedValue: storage)
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView(recipeManager: recipeManager)
                .environment(\.managedObjectContext, DataController.shared.context)
                .environmentObject(purchaseManager)
                                .task {
                                    await purchaseManager.updatePurchasedProducts()
                                }
                .onOpenURL { url in
                    print("### this fires when user opens app via link. the link url is: \(url)")
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting 
                     connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, 
                     userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
//        UserDefaults.standard.set(false, forKey: "inAHousehold") //TESTING only. REMOVE in PROD.
        
        let shareStore = DataController.shared.sharedPersistentStore
        let persistentContainer = DataController.shared.persistentContainer
        
//        DataController.shared.ckContainer.accept(cloudKitShareMetadata) { share, error in }
        persistentContainer.acceptShareInvitations(from: [cloudKitShareMetadata], into: shareStore) { shareMetaData, error in
            if let error = error {
                print("acceptShareInvitation error :\(error)")
                return
            }
            
            let incomingShareRequest = cloudKitShareMetadata.share
            if cloudKitShareMetadata.participantStatus == .accepted,
                !UserDefaults.standard.bool(forKey: "inAHousehold"){
                
                let context = DataController.shared.context
                context.performAndWait {
                    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
                    guard let users = try? context.fetch(fetchRequest) as? [User] else { return }
                    
//                    let userId = currentUser.userIdentity.userRecordID?.recordName
                    let userId = UserDefaults.standard.string(forKey: "userID")!
                    let userAlreadyExists = users.contains(where: { $0.id == userId && $0.isShared == true })
                    guard !userAlreadyExists,
                          let currentUser = incomingShareRequest.currentUserParticipant else { return }
                    
                    let newUser = User(context: DataController.shared.context)
                    newUser.id = userId
                    newUser.name = currentUser.userIdentity.nameComponents?.givenName
                    newUser.userType = 1
                    newUser.isShared = true
                    
                    DataController.shared.context.assign(newUser, to: DataController.shared.sharedPersistentStore)
                    try! DataController.shared.context.save()
                    UserDefaults.standard.set(true, forKey: "inAHousehold")
                }
            }
        }
    }
}
