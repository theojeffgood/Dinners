//
//  RecipesList.swift
//  FryDay
//
//  Created by Theo Goodman on 1/18/23.
//

import SwiftUI

struct RecipesList: View {
    var recipesType: String
    var recipes: [Recipe]
    
    var body: some View {
        if !recipes.isEmpty{
            ScrollView{
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 0),
                                    GridItem(.flexible())]) {
                    ForEach(recipes, id: \.self) { recipe in
                        RecipeCell(recipe: recipe)
                    }
                }
            }.navigationTitle(recipesType)
        } else{
            Text("Add users to your household")
                .navigationTitle(recipesType)
        }
    }
}

struct RecipeCell: View {
    var recipe: Recipe
    
    var body: some View {
        NavigationLink(
            destination: RecipeDetailsView(recipe: recipe, recipeTitle: recipe.title!),
            label: {
                
                VStack(alignment: .center){
                    GeometryReader { geo in
                        AsyncImage(url: URL(string: recipe.imageUrl!)) { image in
                            image
                                .resizable()
//                                .clipped()
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
                        .font(.system(size: 18, weight: .regular))
                }
                .frame(height: 290)
                .cornerRadius(10, corners: .allCorners)
                .padding([.leading, .trailing, .bottom], 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.clear)
                    )
                .shadow(radius: 20)
            })
    }
}

import CoreData

struct RecipesList_Previews: PreviewProvider {
    static let entity = NSManagedObjectModel.mergedModel(from: nil)?.entitiesByName["Recipe"]
    
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
        
        return RecipesList(recipesType: "Matches", recipes: [recipeOne,
                                                             recipeTwo,
                                                             recipeThree])
    }
}
