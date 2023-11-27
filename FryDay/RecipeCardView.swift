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
                
                VStack(spacing: 0) {
                    
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
                    .cornerRadius(10, corners: [.topLeft, .topRight])
                    .shadow(radius: 5)
//                    .frame(width: 350, height: 350) // maybe setting frame here will solve sizing issues?
                    
                    Text(recipe.title!)
                        .multilineTextAlignment(.leading)
                        .padding(.leading)
                        .frame(maxWidth: .infinity,
                               maxHeight: 100,
                               alignment: .leading)
                        .background(.white)
                        .font(.title2)
                        .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                        .shadow(radius: 5)
                }
//user likes OR dislikes via the BUTTONS. NO SWIPE.
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
                            if offset.width < 100{ //left swipe
                                popRecipeStack(true, false)
                                
                            } else if offset.width > 100{ //right swipe
                                popRecipeStack(false, false)
                                
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

//struct RecipeCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeCardView(recipe: )
//        RecipeCardView(recipe: Recipe(recipeId: 5,
//                                      title: "Roasted Asparagus",
//                                     imageUrl: "https://halflemons-media.s3.amazonaws.com/786.jpg"))
//        .previewLayout(.sizeThatFits)
//    }
//}

struct FlatLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
