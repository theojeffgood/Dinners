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
    
    var recipesType: String
    @State var recipes: [Recipe] = []
    
    @State private var showTabbar: Bool = true
    @State private var showHousehold: Bool = false
    var emptyStateMessage = "No matches, yet. \n\n Start liking recipes!"
    
//    var pickerOptions: [String] = ["Matches","Likes"]
//    @State var selectedOption = "Matches"

    var body: some View {
        NavigationStack{
            if !recipes.isEmpty{
                ScrollView{
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 0),
                                        GridItem(.flexible())]) {
                        ForEach(recipes, id: \.self) { recipe in
                            
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
                .onAppear(){ showTabbar = true }
                .navigationTitle(recipesType)
//                .toolbar {
//                    let dropdown = Image(systemName: "chevron.down")
//                    ToolbarItem(placement: .topBarLeading) {
//                        Menu {
//                            Picker("", selection: $selectedOption) {
//                                ForEach(pickerOptions, id: \.self) { option in
//                                    Text(option)
//                                }
//                            }
//                        } label: {
//                            Text("\(selectedOption)\(dropdown)")
//                                .font(.custom("Solway-Regular", size: 14))
//                        }
//                    }
//                }
//                .onChange(of: selectedOption) { newOption in
//                    updateRecipes()
//                }
            } else{
                VStack(spacing: 20, content: {
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text(emptyStateMessage)
                        .multilineTextAlignment(.center)
                        .font(.custom("Solway-Light", size: 30))
                        .padding(.bottom, 55)
                    
                }).navigationTitle(recipesType)
            }
        }
        .toolbar(showTabbar ? .visible : .hidden, for: .tabBar)
        .onAppear(perform: { recipes = recipeManager.getMatches() })
    }
}

struct RecipeCell: View {
    var recipe: Recipe
    
    var body: some View {
        VStack(alignment: .center){
            GeometryReader { geo in
                AsyncImage(url: URL(string: recipe.imageUrl!)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: 200)
                } placeholder: {
                    ProgressView()
                }
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
        .padding([.leading, .trailing, .bottom], 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.clear)
        )
        .shadow(radius: 20)
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
        return RecipesList(recipeManager: recipeManager, recipesType: "Matches", recipes: [recipeOne, recipeTwo, recipeThree])
    }
}
