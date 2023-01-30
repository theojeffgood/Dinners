//
//  RecipesList.swift
//  FryDay
//
//  Created by Theo Goodman on 1/18/23.
//

import SwiftUI

struct RecipesList: View {
    var recipesType: String = "Recipes"
    var recipes: [Recipe]
    
    var body: some View {
        ScrollView{
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]) {
                ForEach(recipes, id: \.self) { recipe in
                    RecipeCell(recipe: recipe)
                }
            }
        }
        .padding([.leading, .trailing], 5.0)
        .navigationTitle(recipesType)
    }
}

struct RecipeCell: View {
    var recipe: Recipe
    
    var body: some View {
        NavigationLink(
            destination: RecipeDetails(recipe: recipe, recipeTitle: recipe.title),
            label: {
                
                VStack(alignment: .center, spacing: 0){
                    AsyncImage(url: URL(string: recipe.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 200)
                    } placeholder: {
                        ProgressView()
                    }
                    .cornerRadius(10, corners: [.topLeft, .topRight])
                    .frame(maxWidth: .infinity)
                    .shadow(radius: 10)
                    
                    Text(recipe.title)
                        .padding(.leading)
                        .frame(maxWidth: .infinity,
                               maxHeight: 100,
                               alignment: .leading)
                        .background(.white)
                        .font(.title2)
                        .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                        .shadow(radius: 20)
                }.padding([.bottom, .top])
                    .padding([.leading, .trailing], 6.0)
            })
    }
}

struct RecipesList_Previews: PreviewProvider {
    static var previews: some View {
        RecipesList(recipesType: "Matches", recipes: [Recipe(recipeId: 1, title: "Chicken Soup"),
            Recipe(recipeId: 2, title: "Korean Style Burgers"),
            Recipe(recipeId: 3, title: "Restaurant Salmon"),
            Recipe(recipeId: 4, title: "Huevos Rotos"),
            Recipe(recipeId: 5, title: "Oven Roasted Asparagus"),
        ])
    }
}
