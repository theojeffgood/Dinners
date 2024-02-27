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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // call appDelegate to handle cloudkit shares.
//    @Environment(\.scenePhase) var scenePhase // "scene phase" i.e. app goes to background
    
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
            TabBarView(recipeManager: recipeManager)
                .environment(\.managedObjectContext, DataController.shared.context)
                .environmentObject(purchaseManager)
//                .environmentObject(ShareCoordinator.shared)
                .task {
                    await purchaseManager.updatePurchasedProducts()
                }
                .onOpenURL { url in } /* Fires when app opens via url aka deeplink. */
        }
//        .onChange(of: scenePhase) { _ in try? moc.save() } /* Fires when app goes to background */
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


import OSLog
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    //Adopted from https://developer.apple.com/forums/thread/699927?answerId=743760022#743760022
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let cloudKitShareMetadata = connectionOptions.cloudKitShareMetadata{
            Logger.share.debug("Handling share invitation via Scene.willConnectTo.")
            joinHouseholdUsing(cloudKitShareMetadata)
        }
    }
    
    func windowScene(_ windowScene: UIWindowScene,
                     userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        Logger.share.debug("Handling share invitation via Scene.userDidAcceptCloudKitShareWith.")
        joinHouseholdUsing(cloudKitShareMetadata)
    }
}

extension SceneDelegate{
    
    func joinHouseholdUsing(_ cloudKitShareMetadata: CKShare.Metadata){
        let shareStore = DataController.shared.sharedPersistentStore
        let persistentContainer = DataController.shared.persistentContainer
        
        persistentContainer.acceptShareInvitations(from: [cloudKitShareMetadata], into: shareStore) { shareMetaData, error in
            if let error = error {
                Logger.share.warning("Failed to accept share invitation: \(error)")
                return
            }
            
//            if UserDefaults.standard.bool(forKey: "inAHousehold"){
//                ShareCoordinator.shared.leaveOtherShares()
//                if UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
//                    UserDefaults.standard.set(false, forKey: "isHouseholdOwner")
//                }
//            }
            
            UserDefaults.standard.set(true, forKey: "inAHousehold")
            
            Logger.share.debug("New participant's share status: \(cloudKitShareMetadata.participantStatus.description, privacy: .public)")
        }
    }
}
