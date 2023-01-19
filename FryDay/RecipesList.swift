//
//  RecipesList.swift
//  FryDay
//
//  Created by Theo Goodman on 1/18/23.
//

import SwiftUI

struct RecipesList: View {
    var recipes: [Recipe]
    
    var body: some View {
        NavigationView {
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
            .padding(.top)
            .navigationTitle("FryDay")
        }
    }
}

struct RecipeCell: View {
    var recipe: Recipe
    
    var body: some View {
        VStack(alignment: .center){
            Text(recipe.title)
            AsyncImage(url: recipe.url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 375)
                    .cornerRadius(15, corners: .allCorners)
            } placeholder: {
                ProgressView()
            }
        }.padding()
    }
}

struct RecipesList_Previews: PreviewProvider {
    static var previews: some View {
        RecipesList(recipes: [
            Recipe(id: 1, title: "Chicken Soup", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2503.jpg")!),
            Recipe(id: 2, title: "Korean Style Burgers", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2502.jpg")!)])
    }
}
