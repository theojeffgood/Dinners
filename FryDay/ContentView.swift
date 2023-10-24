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
    @FetchRequest(sortDescriptors: []) var users: FetchedResults<User>
    
    @State private var recipes: [Recipe] = []
    @State private var recipeOffset: Int = 0
    @State private var likes: [Recipe] = []
    @State private var dislikes: [Recipe] = []
    
    @State private var showHousehold: Bool = false
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
                        RecipeCardView(recipe: recipe,
                                       isTopRecipe: (recipe == recipes.last)){ liked, _ in
                            popRecipeStack(liked: liked, delayPop: false)
                        }
                                       .stacked(at: index, in: recipes.count)
                    }
                }
                
                //ACTION BUTTONS
                HStack(spacing: 65) {
                    Button(action: {
                        popRecipeStack(liked: false)
                    }) {
                        Image(systemName: "xmark").actionStyle(accept: false)
                    }
                    
                    Button(action: {
                        popRecipeStack(liked: true)
                    }) {
                        Text("✓").actionStyle(accept: true)
                    }
                }
                .padding(.top, 25)
            }
            .padding()
            .navigationTitle("Fryday")
            .navigationBarItems(
                trailing:
                    Button{
                        withAnimation {
                            showHousehold = true
                        }
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .tint(.black)
                    }
            )
        }.overlay(alignment: .bottom) {
            if showHousehold{
                let dismiss = {
                    withAnimation {
                        showHousehold = false
                    }
                }
                Household(dismissAction: dismiss)
            }
        }
        .ignoresSafeArea()
        .accentColor(.black)
        .onAppear(){
            loadRecipes()
            
            if users.isEmpty{
                let user = User(context: moc)
                user.id = UUID()
                user.name = "Theo"
                user.userType = 1
                try? moc.save()
            } else{
                users.forEach { user in
                    print("user is: \(user)")
                    print("user recipes are: \(user.likedRecipes)")
                }
            }
        }
        
//---------SHOW JOINING-A-HOUSEHOLD ONBOARDING HERE
//        .onOpenURL { url in
//            withAnimation {
//                showHousehold = true
//            }
//            print("url is: \(url)")
//        }
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
    
    func popRecipeStack(liked: Bool, delayPop: Bool = true){
//1 - show swipe animation
        if delayPop{
            NotificationCenter.default.post(name: Notification.Name.swipeNotification,
                                            object: "Swiped", userInfo: ["swipeRight": liked])
        }
        
//2 - add + remove recipe
        DispatchQueue.main.asyncAfter(deadline: .now() + (delayPop ? 0.3 : 0.0)) {
            withAnimation {
                removeCard()
                addNewCard()
            }
            
//3 - record the like / dislike
            guard let recipe = recipes.last else { return }
            liked ? likes.append(recipe) : dislikes.append(recipe)
            
//4 - save the like / dislike
            if let user = users.first{
                user.addToLikedRecipes(recipe)
                recipe.addToUser(user)
                try? moc.save()
            }
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
                        .frame(width: 125, height: 45)
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
                        .frame(width: 125, height: 45)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                })
            
//            NavigationLink(
//                destination: RecipesList(recipesType: "Dislikes",
//                                         recipes: dislikes),
//                label: {
//                    Text("👎 Dislikes")
//                        .frame(width: 115, height: 35)
//                        .foregroundColor(.black)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 5)
//                                .stroke(Color.black, lineWidth: 1)
//                        )
//                })
//            
            Spacer()
        }
    }
    
}

extension View{
    func actionStyle(accept: Bool) -> some View{
        
        //CHECK-MARK
        if accept{
            self
            .frame(width: 90, height: 90)
            .background(Color.green) // green
            .foregroundColor(.black) // black text
            .cornerRadius(45)
            .font(.system(size: 48, weight: .heavy))
            .shadow(radius: 25)
        }
        
        //X-MARK
        else{
            self
            .frame(width: 90, height: 90)
            .background(Color.red) // red
            .foregroundColor(.white) // white text
            .cornerRadius(45)
            .font(.system(size: 48, weight: .bold))
            .shadow(radius: 25)
        }
    }
}
