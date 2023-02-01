//
//  RecipeDetails.swift
//  FryDay
//
//  Created by Theo Goodman on 1/19/23.
//

import SwiftUI

struct RecipeDetails: View {
    var recipe: Recipe
    var recipeTitle: String = "Recipe Title"
    
    var body: some View {
        List {
            Section(header: RecipeImage(recipe: recipe),
                    footer: Text(recipe.title)
                .multilineTextAlignment(.leading)
                .foregroundColor(.black)
                .font(.system(size: 25))) { } //EMPTY
            
            Section(header: Text("Ingredients")
                .frame(height: 45)
                .foregroundColor(.black)
                .font(.system(size: 18))
            ) {
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    Text("ingredient with id: \(ingredient)")
                }
            }
            
            Section(header: Text("Steps")
                .frame(height: 45)
                .foregroundColor(.black)
                .font(.system(size: 20))
            ) {
                Text("step 1")
                Text("step 2")
                Text("step 3")
            }
        }
//        .ignoresSafeArea(edges: [.leading, .trailing, .bottom])
        .ignoresSafeArea()
//        .navigationTitle(recipeTitle)
    }
}

struct RecipeDetails_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetails(recipe:
                        Recipe(recipeId: 1,
                               title: "Chicken Soup"))
    }
}

struct RecipeImage: View {
    var recipe: Recipe
    
    var body: some View {
        AsyncImage(url: URL(string: recipe.imageUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 500, height: 650)
        } placeholder: {
            ProgressView()
        }
        .cornerRadius(10, corners: [.topLeft, .topRight])
//        .frame(width: 500)
        .shadow(radius: 10)
    }
}
