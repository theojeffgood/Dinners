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
                    footer: TitleAndFacts(recipe: recipe, recipeFacts: recipeDetails?.facts ?? [])
                .padding()
                .frame(width: 395, height: 200, alignment: .leading)
                .multilineTextAlignment(.leading)
                .background(.yellow)
                .foregroundColor(.black)) { } //EMPTY
            
            Section(header: Text("Ingredients")
                .frame(width: 500, height: 55)
                .foregroundColor(.black)
                .font(.system(size: 25, weight: .regular))
            ) {
                ForEach(recipeDetails?.ingredients ?? [], id: \.self) { ingredient in
                    HStack(){
                        Text(" \u{2022}   ")
                            .font(.system(size: 21))
                        Text("\(ingredient.ingredientText)")
                            .font(.system(size: 21))
                    }.padding([.top, .bottom], 6)
                }
            }
            
            Section(header: Text("Steps")
                .frame(width: 500, height: 55)
                .foregroundColor(.black)
                .font(.system(size: 25, weight: .regular))
            ) {
                ForEach(recipeDetails?.steps ?? [], id: \.self) { step in
                    let backgroundColor = step.stepNumber.isMultiple(of: 2) ? Color.gray.opacity(0.1) : Color.white
                    
                    VStack(alignment: .leading, spacing: 20){
                        Text("Step \(step.stepNumber)")
                            .font(.system(size: 21, weight: .heavy))
                        Text("\(step.stepText)")
                            .font(.system(size: 21))
                    }
                    .listRowBackground(backgroundColor)
                    .padding([.top,.bottom])
                }
            }
        }
        .ignoresSafeArea()
        .listStyle(.grouped)
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
        let height = UIScreen.main.bounds.size.height - 250
        AsyncImage(url: URL(string: recipe.imageUrl)) { image in
            image
                .resizable()
                .ignoresSafeArea()
                .aspectRatio(contentMode: .fill)
                .frame(width: 500, height: height)
        } placeholder: {
            ProgressView()
        }
        .cornerRadius(10, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
}

struct TitleAndFacts: View {
    var recipe: Recipe
    var recipeFacts: [Fact]
    
    var body: some View {
        VStack(alignment: .leading){
            Text((recipe.title))
                .font(.system(size: 30, weight: .medium))
                .padding(.top)
            
            Spacer()
            
            HStack(alignment: .center){
                let width = (UIScreen.main.bounds.size.width) / 3
                ForEach(recipeFacts, id: \.self) { fact in
                    
                    switch fact.factType{
                    case 1, 2:
                        Text("\(fact.factText)")
                            .font(.system(size: 18, weight: .regular))
                            .frame(width: width, alignment: .leading)
                            .multilineTextAlignment(.center)
                    case 3:
                        Text("\(fact.factText) Minutes")
                            .font(.system(size: 18, weight: .regular))
                            .frame(width: width, alignment: .leading)
                            .multilineTextAlignment(.center)
                    default:
                        Text("This shouldn't happen")
                    }
                }
            }.padding(.bottom)
        }
        
    }
}
