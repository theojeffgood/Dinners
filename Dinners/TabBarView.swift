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
    
    @State private var selectedItem = 1
    
    var body: some View {
        TabView(selection: $selectedItem) {
            ContentView(recipeManager: recipeManager, filterManager: filterManager)
            .tabItem {
                Image(.fryingpan)
                Text("Recipes   ")
            }.tag(1)
            
            RecipesList(recipeManager: recipeManager)
            .tabItem {
                Label("Favorites", systemImage: "heart")
            }.tag(2)
            
            Household()
            .tabItem {
                Label("Household", systemImage: "person.2.fill")
            }.tag(3)
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
