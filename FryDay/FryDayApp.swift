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
//    @Environment(\.scenePhase) var scenePhase //track changes of scene phase e.g. app goes to background
    
    @StateObject var recipeManager: RecipeManager
    @StateObject private var purchaseManager: PurchaseManager
    
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
//        .onChange(of: scenePhase) { newValue in
//            try? DataController.shared.context.save()
//            print("### CHANGE OF APP SCENE PHASE")
//        } //save context when app goes to background
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
//                print("acceptShareInvitation error :\(error)")
                fatalError("FAILED TO CREATE HOUSEHOLD USER Point #00")
//                return
            }
            
////            CKAcceptSharesOperation() -- is this needed to accept share invites?
//            
//            let incomingShareRequest = cloudKitShareMetadata.share
////            if cloudKitShareMetadata.participantStatus == .accepted,
//                if !UserDefaults.standard.bool(forKey: "inAHousehold"){
//                
//                let context = DataController.shared.context
//                context.performAndWait {
//                    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: User.self))
//                    guard let users = try? context.fetch(fetchRequest) as? [User] else { fatalError("FAILED TO CREATE HOUSEHOLD USER Point #0") }
//                    
////                    let userId = currentUser.userIdentity.userRecordID?.recordName
//                    let userId = UserDefaults.standard.string(forKey: "userID")!
////                    let userAlreadyExists = users.contains(where: { $0.id == userId && $0.isShared == true })
//                    let userAlreadyExists = users.contains(where: { $0.id == userId })
//                    guard !userAlreadyExists,
//                          let currentUser = incomingShareRequest.currentUserParticipant else { fatalError("FAILED TO CREATE HOUSEHOLD USER Point #1") }
//                    
//                    let newUser = User(context: DataController.shared.context)
//                    newUser.id = userId
//                    newUser.name = currentUser.userIdentity.nameComponents?.givenName
//                    newUser.userType = 1
////                    newUser.isShared = true
//                    
//                    DataController.shared.context.assign(newUser, to: DataController.shared.sharedPersistentStore)
//                    try! DataController.shared.context.save()
                    UserDefaults.standard.set(true, forKey: "inAHousehold")
//                }
//            } else{
//                fatalError("FAILED TO CREATE HOUSEHOLD USER Point #2")
//            }
        }
    }
}
