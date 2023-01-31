//
//  RecipeCardView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/26/23.
//

import SwiftUI

struct RecipeCardView: View{
    var recipe: Recipe
    var remove: (() -> Void)? = nil
//    var showRecipeDetails: (() -> Void)? = nil
    
    @State private var offset = CGSize.zero
    
    var body: some View{
        NavigationLink(
            destination: RecipeDetails(recipe: recipe, recipeTitle: recipe.title),
            label: {
                
                VStack(spacing: 0) {
                    AsyncImage(url: URL(string: recipe.imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 350, height: 350)
                            .clipped()
                    } placeholder: {
                        ProgressView()
                    }
                    .cornerRadius(10, corners: [.topLeft, .topRight])
                    .shadow(radius: 10)
                    
                    Text(recipe.title)
                        .multilineTextAlignment(.leading)
                        .padding(.leading)
                        .frame(maxWidth: .infinity,
                               maxHeight: 100,
                               alignment: .leading)
                        .background(.white)
                        .font(.title2)
                        .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                        .shadow(radius: 10)
                }
                .rotationEffect(.degrees(Double(offset.height / 10)))
                .offset(x: offset.width, y: 0)
                .opacity(2 - Double(abs(offset.width / 50) ))
                .gesture(
                    DragGesture()
                        .onChanged({ gesture in
                            offset = gesture.translation
                        })
                        .onEnded({ gesture in
                            if abs(offset.width) > 100{
                                remove?()
                            } else {
                                offset = .zero
                            }
                        })
                )
            })
    }
}

struct RecipeCardView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeCardView(recipe: Recipe(recipeId: 5,
                                      title: "Roasted Asparagus",
                                     imageUrl: "https://halflemons-media.s3.amazonaws.com/786.jpg"))
        .previewLayout(.sizeThatFits)
    }
}
