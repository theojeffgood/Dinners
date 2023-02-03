//
//  RecipeDetailsView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/19/23.
//

import SwiftUI

struct RecipeDetailsView: View {
    var recipe: Recipe
    var recipeTitle: String = "Recipe Title"
    @State var recipeDetails: RecipeDetails? = nil
    
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
                ForEach(recipeDetails?.ingredients ?? [], id: \.self) { ingredient in
                    Text("\u{2022}  \(ingredient.ingredientText)")
                        .font(.system(size: 20))
                }
            }
            
            Section(header: Text("Steps")
                .frame(width: 500, height: 45)
                .foregroundColor(.black)
                .font(.system(size: 25, weight: .regular))
            ) {
                ForEach(recipeDetails?.steps ?? [], id: \.self) { step in
                    let backgroundColor = step.stepNumber.isMultiple(of: 2) ? Color.white : Color.gray.opacity(0.3)
                    
                    Text("Step \(step.stepNumber)\n\n\(step.stepText)")
                        .font(.system(size: 20))
                        .background(backgroundColor)
                        .padding([.top,.bottom])
                    
//                    if step.stepNumber.isMultiple(of: 2){
//                        .background(.gray)
//                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear(){
            loadDetails(for: recipe)
        }
//        .navigationTitle(recipeTitle)
    }
    
    func loadDetails(for recipe: Recipe){
        Task {
            recipeDetails = try await Webservice().load (RecipeDetails.byId(recipe.recipeId))
        }
    }
}

struct RecipeDetails_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailsView(recipe:
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
