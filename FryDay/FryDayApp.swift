//
//  FryDayApp.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI

@main
struct FryDayApp: App {
    @StateObject private var dataController = DataController()
    
    init() { }

    var body: some Scene {
        let managedObjectContext = dataController.container.viewContext
        
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, managedObjectContext)
                .onOpenURL { url in
                    let user = User(context: managedObjectContext)
                    user.id = UUID()
                    user.userType = UserType.pending.rawValue
                    try? managedObjectContext.save()
                    print("url is: \(url)")
                }
        }
    }
}
