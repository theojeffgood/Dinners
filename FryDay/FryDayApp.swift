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
            MainView(recipeManager: recipeManager)
                .environment(\.managedObjectContext, DataController.shared.context)
                .environmentObject(purchaseManager)
                .environmentObject(ShareCoordinator.shared)
                .task {
                    ShareCoordinator.shared.fetchShare() // is this needed? since it's now part of household onAppear.
                    await purchaseManager.updatePurchasedProducts()
                }
                .onOpenURL { url in } /* Fires when app opens via deeplink. Link is url. */
//            ContentView(recipeManager: recipeManager)
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
    func windowScene(_ windowScene: UIWindowScene, 
                     userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        
        let shareStore = DataController.shared.sharedPersistentStore
        let persistentContainer = DataController.shared.persistentContainer
        persistentContainer.acceptShareInvitations(from: [cloudKitShareMetadata], into: shareStore) { shareMetaData, error in
            if let error = error {
                print("### shareInvitation error :\(error)")
                Logger.sharing.warning("Failed to accept share invitation: \(error)")
                return
            }
            
////            CKAcceptSharesOperation() -- is this needed to accept share invites?
            
            UserDefaults.standard.set(true, forKey: "inAHousehold")
            Logger.sharing.debug("New share participant status is (cloudKitShareMetadata.participantStatus.rawValue): \(cloudKitShareMetadata.participantStatus.rawValue)")
        }
    }
}
