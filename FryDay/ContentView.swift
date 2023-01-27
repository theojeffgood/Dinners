//
//  ContentView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI

struct ContentView: View {
//    var recipes: [Recipe] -- this throws an error
    @State private var recipes: [Recipe] = [Recipe(id: 1, title: "Chicken Cacciatore", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2501.jpg")!),
     Recipe(id: 2, title: "Korean Style Burgers", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2502.jpg")!),
     Recipe(id: 3, title: "Restaurant Salmon", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2403.jpg")!),
     Recipe(id: 4, title: "Huevos Rotos", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2302.jpg")!),
     Recipe(id: 5, title: "Oven Roasted Asparagus", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2203.jpg")!)]
    var rejectAction: () -> Void?
    var acceptAction: () -> Void?
    
    @State private var showHousehold: Bool = false
    
    var body: some View {
        NavigationView {
                VStack {
                    Text("Filter")
                        .frame(maxWidth: .infinity,
                               alignment: .leading)
                        .font(.title3)
                        .foregroundColor(.gray)
                    Spacer()
                    
                    Filters(recipes: recipes)
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    ZStack {
                        ForEach(0..<recipes.count, id: \.self) { index in
                            RecipeCardView(recipe: recipes[index]){
                                withAnimation {
                                    removeCard(at: index)
                                }
                            }
                            .stacked(at: index, in: recipes.count)
                        }
                    }
                    
                    HStack {
                        Button(action: {
                            removeCard()
//                            rejectAction()
                        }) {
                            Image(systemName: "xmark")
                                .frame(width: 90, height: 90)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(45)
                                .font(.system(size: 48, weight: .bold))
                                .shadow(radius: 25)
                        }
                        Spacer()
                        Button(action: {
                            removeCard()
//                            acceptAction()
                        }) {
                            Text("✓")
                                .frame(width: 90, height: 90)
                                .background(Color.green)
                                .foregroundColor(.black)
                                .cornerRadius(45)
                                .font(.system(size: 48, weight: .heavy))
                                .shadow(radius: 25)
                        }
                    }
                    .padding([.top, .bottom])
                }
                .padding()
                .navigationTitle("FryDay")
                .navigationBarItems(
                    trailing:
                        Button{
                            print("home button tapped")
                            withAnimation {
                                showHousehold = true
                            }
                        } label: {
                            Image(systemName: "house.fill")
                                .tint(.black)
                        }
                )
        }.overlay(alignment: .bottom) {
            if showHousehold{
                let dismissHousehold = {
                    withAnimation {
                        showHousehold = false
                    }
                }
                Household(dismissAction: dismissHousehold)
            }
        }.ignoresSafeArea()
    }
}

extension ContentView{
    func removeCard(at index: Int? = nil){
        if let index = index{
            recipes.remove(at: index)
        } else{
            let topRecipeIndex = recipes.endIndex
            recipes.remove(at: topRecipeIndex - 1)
        }
        if recipes.isEmpty{
            loadRecipes()
        }
    }
    
    func loadRecipes(){
        recipes = [Recipe(id: 1, title: "Chicken Cacciatore", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2501.jpg")!),
         Recipe(id: 2, title: "Korean Style Burgers", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2502.jpg")!),
         Recipe(id: 3, title: "Restaurant Salmon", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2403.jpg")!),
         Recipe(id: 4, title: "Huevos Rotos", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2302.jpg")!),
         Recipe(id: 5, title: "Oven Roasted Asparagus", url: URL(string: "https://halflemons-media.s3.amazonaws.com/2203.jpg")!)]
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
                    rejectAction: {}, acceptAction: {})
    }
}


//MARK: -- Extensions


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position)
        return self.offset(x: offset * 2, y: offset * 4)
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

//MARK: -- Extractions

struct Filters: View {
    var recipes: [Recipe]
    
    var body: some View{
        HStack() {
            NavigationLink(
                destination: RecipesList(recipesType: "Matches",
                                         recipes: recipes),
                label: {
                    Text("❤️ Matches")
                        .frame(width: 115, height: 35)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                })
            
            NavigationLink(
                destination: RecipesList(recipesType: "Likes",
                                         recipes: recipes),
                label: {
                    Text("👍  Likes")
                        .frame(width: 115, height: 35)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                })
            
            NavigationLink(
                destination: RecipesList(recipesType: "Dislikes",
                                         recipes: recipes),
                label: {
                    Text("👎 Dislikes")
                        .frame(width: 115, height: 35)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                })
            
            Spacer()
        }
    }
    
}
