//
//  FryDayApp.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI

@main
struct FryDayApp: App {
    
    init() { }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("url is: \(url)")
                }
        }
    }
}
