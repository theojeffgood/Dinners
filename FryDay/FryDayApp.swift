//
//  FryDayApp.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI

@main
struct FryDayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(recipes: [], rejectAction: {}, acceptAction: {})
        }
    }
}

struct Recipe: Hashable {
    var id: Int
    var title: String
    var url: URL
}


