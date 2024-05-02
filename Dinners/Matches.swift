//
//  RecipesList.swift
//  FryDay
//
//  Created by Theo Goodman on 1/18/23.
//

import SwiftUI
import CloudKit

struct RecipesList: View {
    
    @ObservedObject var recipeManager: RecipeManager
    @FetchRequest(fetchRequest: Vote.allVotes) var allVotes
    @State private var showTabbar: Bool = true

    var body: some View {
        NavigationStack{
            VStack{
                Picker("Recipes?", selection: $recipeManager.recipeType) {
                    ForEach(RecipeType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 10)
                
                if !recipeManager.recipes.isEmpty{
                    ScrollView{
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 0),
                                            GridItem(.flexible())]) {
                            ForEach(recipeManager.recipes, id: \.self) { recipe in
                                
                                NavigationLink {
                                    RecipeDetailsView(recipe: recipe,
                                                      recipeTitle: recipe.title!)
                                    .onAppear(perform: {
                                        withAnimation { showTabbar = false }
                                    })
                                }
                            label: { RecipeCell(recipe: recipe) }
                            }
                        }
                    }
                } else{
                    let emptyStateMessage = recipeManager.recipeType.emptyState
                    EmptyState(message: emptyStateMessage)
                }
            }.navigationTitle("Matches")
                .onAppear{
                    showTabbar = true
                    recipeManager.getMatches()
                }
        }.toolbar(showTabbar ? .visible : .hidden, for: .tabBar)
    }
}

struct RecipeCell: View {
    var recipe: Recipe
    
    var body: some View {
        VStack(alignment: .center){
            GeometryReader { geo in
                AsyncImage(url: URL(string: recipe.imageUrl!)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ProgressView()
                    }
                }.frame(width: geo.size.width, height: 200)
            }
            
            Text(recipe.title!)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity,
                       maxHeight: 100,
                       alignment: .leading)
                .background(.white)
                .font(.custom("Solway-Light", size: 18))
                .foregroundColor(.black)
        }
        .frame(height: 290)
        .cornerRadius(10, corners: .allCorners)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.clear)
        )
        .shadow(radius: 10)
    }
}

struct EmptyState: View {
    var message: String
    
    var body: some View {
        Spacer()
        VStack(spacing: 20, content: {
            Image(systemName: "person.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray.opacity(0.6))
            
            Text(message)
                .multilineTextAlignment(.center)
                .font(.custom("Solway-Light", size: 30))
                .padding(.bottom, 55)
            
        }).navigationTitle("Matches")
        Spacer()
    }
}

enum RecipeType: String, CaseIterable {
    case matches = "Matches"
    case likes   = "My Likes"
    
    var emptyState: String{
        switch self {
        case .matches:
            return "No matches, yet. \n\n Add people to your household."
        case .likes:
            return "No likes, yet. \n\n Start liking recipes."
        }
    }
}

import CoreData

struct RecipesList_Previews: PreviewProvider {
    static let entity = NSManagedObjectModel
        .mergedModel(from: nil)?
        .entitiesByName["Recipe"]
    
    static var previews: some View {
        let recipeOne = Recipe(entity: entity!, insertInto: nil)
        recipeOne.title = "Chicken Parm"
        recipeOne.imageUrl = "https://halflemons-media.s3.amazonaws.com/786.jpg"
        
        let recipeTwo = Recipe(entity: entity!, insertInto: nil)
        recipeTwo.title = "Split Pea Soup"
        recipeTwo.imageUrl = "https://halflemons-media.s3.amazonaws.com/785.jpg"
        
        let recipeThree = Recipe(entity: entity!, insertInto: nil)
        recipeThree.title = "BBQ Ribs"
        recipeThree.imageUrl = "https://halflemons-media.s3.amazonaws.com/784.jpg"
        
        let moc = DataController.shared.context
        let recipeManager = RecipeManager(managedObjectContext: moc)
        
        //        return RecipesList(recipesType: "Matches", recipes: [])
//        return RecipesList(recipeManager: recipeManager, recipesType: "Matches", recipes: [recipeOne, recipeTwo, recipeThree])
        return RecipesList(recipeManager: recipeManager)
    }
}
