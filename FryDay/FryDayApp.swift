//
//  FryDayApp.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI
import CloudKit

@main
struct FryDayApp: App {
    
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @StateObject var userManager: UserManager
    
    init() {
//        let storage = UserManager(managedObjectContext: DataController.shared.context)
//        self._userManager = StateObject(wrappedValue: storage)
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, DataController.shared.context)
                .onOpenURL { url in
//                    let user = User(context: managedObjectContext)
                    
//                    let user = User(context: DataController.shared.context)
//                    user.id = UUID()
//                    user.userType = UserType.pending.rawValue
                    
//                    try? managedObjectContext.save() //uncomment this
                    print("url is: \(url)")
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
        
        let shareStore = DataController.shared.sharedPersistentStore
        let persistentContainer = DataController.shared.persistentContainer
        
        persistentContainer.acceptShareInvitations(from: [cloudKitShareMetadata], into: shareStore) { shareMetaData, error in
            if let error = error {
                print("acceptShareInvitation error :\(error)")
                return
            }
            
            if let zoneShare = cloudKitShareMetadata.rootRecord as? CKShare,
            let currentUser = zoneShare.currentUserParticipant, /*<-- put this in userManager? use it to gatekeep new user management*/
//            if !users.contains(currentUser){ addNewUser }
            
//                cloudKitShareMetadata.participantStatus == .accepted{
                currentUser.acceptanceStatus == .accepted{
                let newUser = User()
                newUser.name = currentUser.userIdentity.userRecordID?.recordName
                newUser.name = currentUser.userIdentity.nameComponents?.givenName
                newUser.userType = 1
                try? DataController.shared.context.save()
            }
        }
    }
}
