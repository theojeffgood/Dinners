//
//  TabBarView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/25/24.
//

import SwiftUI
import CloudKit

struct TabBarView: View {
    
    @ObservedObject var recipeManager: RecipeManager
    @ObservedObject var filterManager: FilterManager
    
    var body: some View {
        TabView {
            ContentView(recipeManager: recipeManager, filterManager: filterManager)
            .tabItem {
                Label("Menu", systemImage: "frying.pan")
            }
            
            RecipesList(recipeManager: recipeManager, recipesType: "Matches")
            .tabItem {
                Label("Matches", systemImage: "link")
            }
            
            RecipesList(recipeManager: recipeManager, 
                        recipesType: "Likes")
            .tabItem {
                Label("Likes", systemImage: "heart")
            }
        }
        .accentColor(.black)
    }
}

import CoreData

#Preview {
    let entity = NSManagedObjectModel
        .mergedModel(from: nil)?
        .entitiesByName["Recipe"]
    let recipeOne = Recipe(entity: entity!, insertInto: nil)
    recipeOne.title = "Eggs and Bacon"
    recipeOne.imageUrl = "https://halflemons-media.s3.amazonaws.com/787.jpg"
    
    let moc = DataController.shared.context
    let filterManager = FilterManager(managedObjectContext: moc)
    let recipeManager = RecipeManager(managedObjectContext: moc)
    recipeManager.recipe = recipeOne
    
    return TabBarView(recipeManager: recipeManager, filterManager: filterManager)
}
