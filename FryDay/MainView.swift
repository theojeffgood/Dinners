//
//  MainView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/25/24.
//

import SwiftUI
import CloudKit

struct MainView: View {
    
    @EnvironmentObject private var shareCoordinator: ShareCoordinator
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var recipeManager: RecipeManager
    
    @FetchRequest(fetchRequest: Vote.allVotes) var allVotes
    
    private var matches: [Recipe]{
        let matches = recipeManager.getMatches()
        return matches
    }
    
    private var likes: [Recipe]{
        let votedRecipeIds = allVotes.filter({ $0.isLiked && $0.isCurrentUser }).map({ $0.recipeId })
        let recipes = recipeManager.getRecipesById(ids: votedRecipeIds)
        return recipes ?? []
    }
    
    var body: some View {
        TabView {
            ContentView(recipeManager: recipeManager)
                .tabItem {
                    Label("Menu", systemImage: "frying.pan")
                }
            
            RecipesList(recipesType: "Matches",
                        recipes: matches)
            .tabItem {
                Label("Matches", systemImage: "link")
            }
            
            RecipesList(recipesType: "Likes",
                        recipes: likes)
            .tabItem {
                Label("Likes", systemImage: "heart")
            }
        }
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
    let recipeManager = RecipeManager(managedObjectContext: moc)
    recipeManager.recipe = recipeOne
    
    return MainView(recipeManager: recipeManager)
}
