//
//  RecipeDetailsView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/19/23.
//

import SwiftUI

struct RecipeDetailsView: View {
    
    @Environment(\.managedObjectContext) var moc
    
    var recipe: Recipe
    var recipeTitle: String = "Recipe Title"
    @State var recipeDetails: RecipeDetails? = nil
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section(header: RecipeImage(recipe: recipe),
                        footer: TitleAndFacts(recipe: recipe, recipeFacts: recipeDetails?.facts ?? [])
                    .frame(width: geo.size.width, height: 215, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .background(.yellow)
                    .foregroundColor(.black)) { } //EMPTY
                
                Section(header: Text("Ingredients")
                    .frame(width: geo.size.width, height: 55)
                    .foregroundColor(.black)
                    .font(.custom("Solway-Regular", size: 30))
                ) {
                    ForEach(recipeDetails?.ingredients ?? [], id: \.self) { ingredient in
                        HStack(){
                            Text(" \u{2022}   ")
                                .font(.custom("Solway-Extrabold", size: 19))
                            Text("\(ingredient.ingredientText)")
                                .font(.custom("Solway-Light", size: 19))
                        }
                        .padding([.top, .bottom], 6)
                    }
                }
                
                Section(header: Text("Steps")
                    .frame(width: geo.size.width, height: 55)
                    .foregroundColor(.black)
                    .font(.custom("Solway-Regular", size: 30))
                ) {
                    ForEach(recipeDetails?.steps ?? [], id: \.self) { step in
                        let backgroundColor = step.stepNumber.isMultiple(of: 2) ? Color.gray.opacity(0.1) : Color.white
                        
                        VStack(alignment: .leading, spacing: 20){
                            Text("Step \(step.stepNumber)")
                                .font(.custom("Solway-Extrabold", size: 18))
                            Text("\(step.stepText)")
                                .font(.custom("Solway-Light", size: 18))
                        }
                        .listRowBackground(backgroundColor)
                        .padding([.top,.bottom])
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .ignoresSafeArea()
            .listStyle(.grouped)
            .onAppear(){
                loadDetails(for: recipe)
            }
        }
//        .navigationTitle(recipeTitle)
    }
    
    func loadDetails(for recipe: Recipe){
        Task {
            recipeDetails = try await Webservice(context: moc).load (RecipeDetails.byId(Int(recipe.recipeId)))
        }
    }
}

import CoreData

struct RecipeDetails_Previews: PreviewProvider {
    static let entity = NSManagedObjectModel
        .mergedModel(from: nil)?
        .entitiesByName["Recipe"]
    
    static var previews: some View {
        let recipeOne = Recipe(entity: entity!, insertInto: nil)
        recipeOne.title = "Chicken Parm"
        recipeOne.imageUrl = "https://halflemons-media.s3.amazonaws.com/786.jpg"
        
        return RecipeDetailsView(recipe: recipeOne)
    }
}

struct RecipeImage: View {
    var recipe: Recipe
    
    var body: some View {
        let height = UIScreen.main.bounds.size.height - 250
        AsyncImage(url: URL(string: recipe.imageUrl!)) { image in
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
            Text((recipe.title!))
                .font(.custom("Solway-Regular", size: 35))
                .padding([.leading, .top, .trailing])
            
            Spacer()
            
            HStack(alignment: .center){
                let width = (UIScreen.main.bounds.size.width) / 3
                ForEach(recipeFacts, id: \.self) { fact in
                    
                    switch fact.factType{
                    case 1, 2: //recipe source & servings
                        Text("\(fact.factText)")
                            .font(.custom("Solway-Regular", size: 18))
                            .frame(width: width, alignment: .leading)
                            .multilineTextAlignment(.center)
                        
                    case 3: //recipe cooktime
                        Text("\(fact.factText) Mins")
                            .font(.custom("Solway-Regular", size: 18))
                            .frame(width: width, alignment: .leading)
                            .multilineTextAlignment(.center)
                        
                    default:
                        Text("Unrecognized recipe facts found.")
                    }
                }
            }.padding()
        }.padding(.bottom)
    }
}
