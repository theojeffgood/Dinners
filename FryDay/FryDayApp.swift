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
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .onOpenURL { url in
                    print("url is: \(url)")
                }
        }
    }
}
