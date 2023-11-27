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
//    @StateObject var userManager: UserManager
    
    init() {
        if UserDefaults.standard.string(forKey: "currentUserID") == nil {
            let userId: String = "\(UUID())"
            UserDefaults.standard.set(userId, forKey: "currentUserID")
        }
        
//        let storage = UserManager(managedObjectContext: DataController.shared.context)
//        self._userManager = StateObject(wrappedValue: storage)
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, DataController.shared.context)
                .onOpenURL { url in
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
        UserDefaults.standard.set(false, forKey: "userIsInAHousehold") //TESTING only. REMOVE in PROD.
        
        let shareStore = DataController.shared.sharedPersistentStore
        let persistentContainer = DataController.shared.persistentContainer
        
//        DataController.shared.ckContainer.accept(cloudKitShareMetadata) { share, error in
//            print("SHARE: \(share)")
//        }
        
        persistentContainer.acceptShareInvitations(from: [cloudKitShareMetadata], into: shareStore) { shareMetaData, error in
            if let error = error {
                print("acceptShareInvitation error :\(error)")
                return
            }
            
            let zoneShare = cloudKitShareMetadata.share
                
                if let currentUser = zoneShare.currentUserParticipant{
                    
//                    if currentUser.acceptanceStatus == .accepted{
                    if cloudKitShareMetadata.participantStatus == .accepted{
                        print("USER IS NOW A PARTICIPANT OF THE SHARE. ACCEPTANCE STATUS: \(currentUser.acceptanceStatus)")
                        
                        if !UserDefaults.standard.bool(forKey: "userIsInAHousehold"){
                            
//                            let userId = currentUser.userIdentity.userRecordID?.recordName
                            let userId = UserDefaults.standard.string(forKey: "currentUserID")!
                            
                            let context = DataController.shared.context
                            context.performAndWait {
                                
                                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
                                if let users = try? context.fetch(fetchRequest) as? [User]{
                                    
                                    let userAlreadyExists = users.contains(where: { $0.id == userId && $0.isShared == true })
                                    if !userAlreadyExists{
                                        
                                       let newUser = User(context: DataController.shared.context)
                                        newUser.id = userId
                                        newUser.name = currentUser.userIdentity.nameComponents?.givenName
                                        newUser.userType = 1
                                        newUser.isShared = true
                                        
                                        DataController.shared.context.assign(newUser, to: DataController.shared.sharedPersistentStore)
                                        try! DataController.shared.context.save()
                                        print("CREATING NEW USER WITH PARTICIPANT ID: \(userId)")
                                        
                                    } else{
                                        print("USER ALREADY EXISTS")
                                    }
                                }
                            }
                            UserDefaults.standard.set(true, forKey: "userIsInAHousehold")
                    }
                }
            }
        }
    }
}
