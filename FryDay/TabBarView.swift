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
    
    @State var isPresenting = false
    @State private var selectedItem = 1
    @State private var oldSelectedItem = 1
    
    var body: some View {
        TabView(selection: $selectedItem) {
            ContentView(recipeManager: recipeManager, filterManager: filterManager)
            .tabItem {
                Label("Menu", systemImage: "frying.pan")
            }.tag(1)
            
            RecipesList(recipeManager: recipeManager, recipesType: "Matches")
            .tabItem {
                Label("Matches", systemImage: "link")
            }.tag(2)
            
            Text("")
            .tabItem {
                Label("Household", systemImage: "person.2")
            }.tag(3)
        }
        .sheet(isPresented: $isPresenting) {
            Household(onDismiss: { print("Household") })
        }
        
        .onChange(of: selectedItem) {
            if 3 == selectedItem {
                self.isPresenting = true
                self.selectedItem = self.oldSelectedItem
            } else if (isPresenting == false) {
                self.oldSelectedItem = $0
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
