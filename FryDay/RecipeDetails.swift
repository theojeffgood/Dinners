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
        VStack(alignment: .center, spacing: 0){
            AsyncImage(url: URL(string: recipe.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
//                    .frame(maxWidth: .infinity, maxHeight: 200)
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
        }
        .padding([.bottom, .top])
        
            .navigationTitle(recipeTitle)
    }
}

//struct RecipeDetailsCell: View {
//    var recipe: Recipe
//
//    var body: some View {
//        VStack(alignment: .center){
//            Text(recipe.title)
//            AsyncImage(url: recipe.url) { image in
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(maxWidth: .infinity, maxHeight: 375)
//                    .cornerRadius(15, corners: .allCorners)
//            } placeholder: {
//                ProgressView()
//            }
//        }.padding()
//    }
//}

struct RecipeDetails_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetails(recipe:
                        Recipe(recipeId: 1,
                               title: "Chicken Soup"))}
}
