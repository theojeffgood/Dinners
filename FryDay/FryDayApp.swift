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
            ContentView()
        }
    }
}

struct Recipe: Hashable, Codable {
    var recipeId: Int
    var title: String
    var imageUrl: String = ""
    var source: String = ""
    var ingredients: String = ""
    var websiteUrl: String = ""
    var cooktime: String? = nil
    var recipeStatusId: Int = 1
    
//    var url: URL = URL(string: "https://www.cnn.com")!
}


