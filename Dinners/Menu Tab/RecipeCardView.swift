//
//  RecipeCardView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/26/23.
//

import SwiftUI

struct RecipeCardView: View{
    var recipe: Recipe
    //    var popRecipeStack: ((Bool) -> Void)
    
    //    @State private var isVisible = true
    //    @State private var offset = CGSize.zero
    
    var body: some View{
        ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom), content: {
            
            //            Image Sizing: www.hackingwithswift.com/books/ios-swiftui/resizing-images-to-fit-the-screen-using-geometryreader
            GeometryReader { geo in
                AsyncImage(url: URL(string: recipe.imageUrl!)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            
            Text(recipe.title!)
                .multilineTextAlignment(.leading)
            //                .opacity(isVisible ? (2.0 - Double(abs(offset.width / 50) )) : 0 )
                .foregroundColor(.white)
                .padding(.leading)
                .frame(maxWidth: .infinity,
                       maxHeight: 75,
                       alignment: .leading)
//                .background(.black.opacity(0.4))
                .background(LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom).opacity(0.8))
                .font(.custom("Solway-Regular", size: 20))
        })
        .cornerRadius(10, corners: .allCorners)
        .shadow(radius: 5)
    }
}
//        .rotationEffect(.degrees(Double(offset.width / 30)))
//        .offset(x: offset.width * 0.8, y: offset.height * 0.4)
//        .opacity(isVisible ? (2.0 - Double(abs(offset.width / 50) )) : 0 )
        
//        .transition(.opacity) // 1 of 2
//        .animation(.easeInOut(duration: 0.65), value: recipe) // 2 of 2
        
//        .gesture(
//            DragGesture()
//                .onChanged({ gesture in
//                    offset = gesture.translation
//                })
//                .onEnded({ gesture in
//                    if offset.width < -100{ //left swipe
//                        popRecipeStack(false)
//                        resetOffset()
//                        
//                    } else if offset.width > 100{ //right swipe
//                        popRecipeStack(true)
//                        resetOffset()
//                        
//                    } else{ //no swipe
//                        withAnimation { offset = .zero }
//                    }
//                })
//        )
        
        // like + dislike via Buttons. No swipe.
//        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.showSwipe)) { object in
//            guard let swipeInfo = object.userInfo as? [String: Bool],
//                  let swipeRight = swipeInfo["swipeRight"] else { return }
//            setOffset(swipeRight: swipeRight)
//        }
//    }
    
//    func setOffset(swipeRight: Bool){
//        if #available(iOS 17.0, *) {
//            withAnimation(.easeInOut(duration: 0.5)) {
//                let width = swipeRight ? 200 : -200
//                offset = CGSize(width: width, height: 0)
//                print("###Animating swipe")
//            } completion: {
//                print("###Completion handler for swipe animation")
//                resetOffset()
//            }
//        }
//    }
    
//    func resetOffset(){
//        print("###Resetting offset")
//        isVisible = false
//        offset = .zero
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//            print("###Animating visibility")
//            withAnimation(.easeInOut(duration: 0.375)) {
//                isVisible = true
//            }
//        }
//    }
    
//    func colorForOffset(_ offset: CGSize) -> Color{
//        switch offset.width{
//        case 0:
//            return .clear
//        case 0.1 ..< 1000:
//            return .green
//        case -1000 ..< 0.1:
//            return .red
//        default:
//            return .clear
//        }
//    }
//}

//extension Notification.Name {
//    static let showSwipe = Notification.Name("showSwipe")
//    //    static let resetOffset       = Notification.Name("resetOffset")
//}

import CoreData

struct RecipeCardView_Previews: PreviewProvider {
    static let entity = NSManagedObjectModel.mergedModel(from: nil)?.entitiesByName["Recipe"]
    
    static var previews: some View {
        let recipeOne = Recipe(entity: entity!, insertInto: nil)
        recipeOne.title = "Chicken Parm"
        recipeOne.imageUrl = "https://halflemons-media.s3.amazonaws.com/786.jpg"
        
        return RecipeCardView(recipe: recipeOne).previewLayout(.sizeThatFits)
    }
    
}

//struct FlatLinkStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//    }
//}
