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
//    @StateObject private var dataController = DataController()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
//        let managedObjectContext = dataController.container.viewContext
        
        WindowGroup {
            ContentView()
//                .environment(\.managedObjectContext, managedObjectContext)
                .environment(\.managedObjectContext, DataController.shared.context)
                .onOpenURL { url in
//                    let user = User(context: managedObjectContext)
                    let user = User(context: DataController.shared.context)
                    user.id = UUID()
                    user.userType = UserType.pending.rawValue
//                    try? managedObjectContext.save() //uncomment this
                    print("url is: \(url)")
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    sceneConfig.delegateClass = SceneDelegate.self
    return sceneConfig
  }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
  func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
    let shareStore = DataController.shared.sharedPersistentStore
    let persistentContainer = DataController.shared.persistentContainer
    persistentContainer.acceptShareInvitations(from: [cloudKitShareMetadata], into: shareStore) { _, error in
      if let error = error {
        print("acceptShareInvitation error :\(error)")
      }
    }
  }
}
