//
//  ContentView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI

struct ContentView: View {

    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var allRecipes: FetchedResults<Recipe>
    @State private var recipes: [Recipe] = []
    
    @State private var likes: [Recipe] = []
    @State private var dislikes: [Recipe] = []
    
    @State private var showHousehold: Bool = false
    @State private var recipeOffset: Int = 0
    
    //    @State private var recipes: [Recipe] = [Recipe(recipeId: 1, title: "Chicken Cacciatore", imageUrl: "https://halflemons-media.s3.amazonaws.com/786.jpg")]
    
    var body: some View {
        NavigationView {
            VStack {
                Filters(likes: $likes.wrappedValue,
                        dislikes: $dislikes.wrappedValue)
                .padding(.bottom)
                
                ZStack {
                    ForEach(recipes, id: \.self) { recipe in
                        let index = recipes.firstIndex(of: recipe)!
                        RecipeCardView(recipe: recipe, isTopRecipe: (recipe == recipes.last)){
                            withAnimation {
                                removeCard(at: index)
                                addNewCard()
                            }
                        }
                        .stacked(at: index, in: recipes.count)
                    }
                }
                
                HStack(spacing: 65) {
                    
                    Button(action: {
                        NotificationCenter.default.post(name: Notification.Name.swipeNotification,
                                                        object: "Swiped",
                                                        userInfo: ["swipeRight": false])
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                addNewCard()
                                removeCard()
                                guard let recipe = recipes.last else { return }
                                dislikes.append(recipe)
                            }
                        }
                    }) {
                        Image(systemName: "xmark")
                            .frame(width: 90, height: 90)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(45)
                            .font(.system(size: 48, weight: .bold))
                            .shadow(radius: 25)
                    }
                    Button(action: {
                        NotificationCenter.default.post(name: Notification.Name.swipeNotification,
                                                        object: "Swiped",
                                                        userInfo: ["swipeRight": true])
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                addNewCard()
                                removeCard()
                                guard let recipe = recipes.last else { return }
                                likes.append(recipe)
                            }
                        }
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
                //                    .padding([.top])
                .padding(.top, 25)
            }
            .padding()
            .navigationTitle("FryDay")
            .navigationBarItems(
                trailing:
                    Button{
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
        }
        .ignoresSafeArea()
        .accentColor(.black)
        .onAppear(){
            loadRecipes()
        }
        .onOpenURL { url in
            withAnimation {
                showHousehold = true
            }
            print("url is: \(url)")
        }
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
    
    func addNewCard(){
        guard allRecipes.indices.contains(recipeOffset) else { return }
        let newRecipe = allRecipes[recipeOffset]
        recipes.insert(newRecipe, at: 0)
        recipeOffset += 1
    }
    
    func loadRecipes(){
        if allRecipes.isEmpty{
            Task {
                try await Webservice(context: moc).load (Recipe.all)
                try? moc.save()
                recipes = Array(allRecipes.shuffled()[recipeOffset ... (recipeOffset + 2)])
                recipeOffset = 2
            }
        } else{
            self.recipes = Array(allRecipes.shuffled()[recipeOffset ... (recipeOffset + 2)])
            recipeOffset += 2
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


//MARK: -- Extensions


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position)
        return self.offset(x: 0, y: offset * 9)
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
    var likes: [Recipe] = []
    var dislikes: [Recipe] = []
    
    var body: some View{
        HStack() {
            NavigationLink(
                destination: RecipesList(recipesType: "Matches",
                                         recipes: likes),
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
                                         recipes: likes),
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
                                         recipes: dislikes),
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
