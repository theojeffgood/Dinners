//
//  ContentView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI
import CloudKit

struct ContentView: View {

    @Environment(\.managedObjectContext) var moc
//    @FetchRequest(sortDescriptors: []) var allRecipes: FetchedResults<Recipe>
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "ANY user != nil")) var allRecipes: FetchedResults<Recipe>
    @FetchRequest(sortDescriptors: []) var users: FetchedResults<User>
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "id == %@", UserDefaults.standard.string(forKey: "currentUserID") ?? ""))
    var currentUser: FetchedResults<User>
//    @ObservedObject var userManager: UserManager
    
    private let shareCoordinator = ShareCoordinator()
    
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
                Spacer()
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
//            Task{
//                let shareExists = try? await shareCoordinator.shareExists
//            }
            
            if !UserDefaults.standard.bool(forKey: "userWasCreated"),
               currentUser.isEmpty {
                print("CREATING NEW USER")
                let newUser = User(context: moc)
                
                // Obtain the current user's iCloud user ID
                let currentUserID = CKCurrentUserDefaultName
                
                newUser.id = currentUserID
                newUser.name = "Unknown..."
                newUser.userType = 2
                try? moc.save()
                UserDefaults.standard.set(true, forKey: "userWasCreated")
                UserDefaults.standard.set(currentUserID, forKey: "currentUserID")
            }

            loadRecipes()
        }
        
//---------SHOW JOINING-A-HOUSEHOLD ONBOARDING HERE
//        .onOpenURL { url in
//            print("referring url is: \(url)")
//        }
    }
}

extension ContentView{
    func loadRecipes(){
        if UserDefaults.standard.bool(forKey: "userIsInAHousehold"){
//            let householdUsers = userManager.householdUsers
            let householdUsers = users
            print("householdUsers count is \(householdUsers.count)")
            var likedRecipes: [Recipe] = []
            for user in householdUsers{
                let newRecipes: [Recipe] = user.likedRecipes?.allObjects as? [Recipe] ?? []
                likedRecipes.append(contentsOf: newRecipes)
            }
            self.recipes = likedRecipes /*--??*/
            print("recipes count is \(recipes.count)")

        } else{
//            if allRecipes.isEmpty{
//                Task {
//                    try await Webservice(context: moc).load (Recipe.all)
//                    try? moc.save()
//                    recipes = Array(allRecipes.shuffled()[recipeOffset ... (recipeOffset + 2)])
//                    recipeOffset = 2
//                }
//            }

        }
                   
        if allRecipes.isEmpty{ return }
        self.recipes = Array(allRecipes.shuffled()[recipeOffset ... (recipeOffset + 2)])
//        self.recipes = Array(allRecipes)
        recipeOffset += 2
        print("allRecipes count is: \(allRecipes.count)")
//        }
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
            if let currentUser = users.first{
                
                liked ? currentUser.likes(recipe) : currentUser.dislikes(recipe)
                liked ? recipe.addToUser(currentUser) : recipe.addToUser(currentUser) //generate Recipe files. update addToUser method call.
                
                try? moc.save()
            }
        }
    }

    func removeCard(){
        let topRecipeIndex = recipes.endIndex
        recipes.remove(at: topRecipeIndex - 1)
        
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
//        ContentView(userManager: UserManager(managedObjectContext: DataController.shared.context))
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
                    Text("👍 Likes")
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
