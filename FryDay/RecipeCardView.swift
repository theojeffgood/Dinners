//
//  RecipeCardView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/26/23.
//

import SwiftUI

struct RecipeCardView: View{
    var recipe: Recipe
    var isTopRecipe = false
    var popRecipeStack: ((Bool, Bool) -> Void)
        
    @State private var offset = CGSize.zero
    
    var body: some View{
        NavigationLink(
            destination: RecipeDetailsView(recipe: recipe,
                                       recipeTitle: recipe.title!),
            label: {
                
                ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom), content: {
                    
                    //Image Sizing: www.hackingwithswift.com/books/ios-swiftui/resizing-images-to-fit-the-screen-using-geometryreader
                    GeometryReader { geo in
                        AsyncImage(url: URL(string: recipe.imageUrl!)) { image in
                            image
                                .resizable()
                                .scaledToFill()
//                                .frame(width: 350, height: 250)
                                .frame(width: geo.size.width)
                                .clipped()
                                .opacity(2.0 - Double(abs(offset.width / 50) ))
                                .background(colorForOffset(offset))
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    
                    Text(recipe.title!)
//                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .padding(.leading)
                        .frame(maxWidth: .infinity,
                               maxHeight: 75,
                               alignment: .leading)
                        .background(.black.opacity(0.5))
                        .font(.title3)
                })
                .cornerRadius(10, corners: .allCorners)
                .shadow(radius: 5)
//user likes & dislikes via the BUTTONS. he does NOT swipe.
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.swipeNotification)) { object in
                    if isTopRecipe,
                       let swipeDirection = object.userInfo as? [String: Bool],
                       let swipeRight = swipeDirection["swipeRight"]{
                        setOffset(swipedRight: swipeRight)
                    }
                }
                .rotationEffect(.degrees(Double(offset.width / 30)))
                .offset(x: offset.width * 0.8, y: offset.height * 0.4)
                .opacity(3 - Double(abs(offset.width / 50) ))
                .gesture(
                    DragGesture()
                        .onChanged({ gesture in
                            offset = gesture.translation
                        })
                        .onEnded({ gesture in
                            if offset.width < -100{ //left swipe
                                popRecipeStack(false, false)
                                
                            } else if offset.width > 100{ //right swipe
                                popRecipeStack(true, false)
                                
                            } else{ //cancel swipe
                                withAnimation {
                                    offset = .zero
                                }
                            }
                        })
                )
            }).buttonStyle(FlatLinkStyle()) //disable tap-opacity https://stackoverflow.com/a/62311089
    }
    
    func setOffset(swipedRight: Bool){
        let swipeLength = swipedRight ? 125 : -125
        withAnimation {
            offset = CGSize(width: swipeLength, height: 0)
        }
    }
    
    func colorForOffset(_ offset: CGSize) -> Color{
        switch offset.width{
        case 0:
            return .clear
        case 0.1 ..< 1000:
            return .green
        case -1000 ..< 0.1:
            return .red
        default:
            return .clear
        }
    }
}

extension Notification.Name {
    static let swipeNotification = Notification.Name("swipeNotification")
}

import CoreData

struct RecipeCardView_Previews: PreviewProvider {
    static let entity = NSManagedObjectModel.mergedModel(from: nil)?.entitiesByName["Recipe"]
    
    static var previews: some View {
        let recipeOne = Recipe(entity: entity!, insertInto: nil)
        recipeOne.title = "Chicken Parm"
        recipeOne.imageUrl = "https://halflemons-media.s3.amazonaws.com/786.jpg"
        
        return RecipeCardView(recipe: recipeOne,
                              isTopRecipe: false,
                              popRecipeStack: { _,_ in }).previewLayout(.sizeThatFits)
    }
        
}

struct FlatLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
