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
                .padding()
                .frame(width: 395, height: 150, alignment: .leading)
                .multilineTextAlignment(.leading)
                .background(.yellow)
                .foregroundColor(.black)
                .font(.system(size: 30, weight: .medium))) { } //EMPTY
            
            Section(header: Text("Ingredients")
                .frame(width: 500, height: 45)
                .foregroundColor(.black)
                .font(.system(size: 25, weight: .regular))
            ) {
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    Text("\u{2022}  ingredient with id: \(ingredient)")
                }
            }
            
            Section(header: Text("Steps")
                .frame(width: 500, height: 45)
                .foregroundColor(.black)
                .font(.system(size: 25, weight: .regular))
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
                .ignoresSafeArea()
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
