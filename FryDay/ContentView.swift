//
//  ContentView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    
//    @ObservedObject var userManager: UserManager

    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "isLiked", ascending: false)],
                  predicate: NSPredicate(format: "isShared = %@", UserDefaults.standard.bool(forKey: "inAHousehold") ? "1" : "0"))
//                  predicate:        NSPredicate(format: "isShared == 1"))
    var allRecipes: FetchedResults<Recipe>
    @FetchRequest(sortDescriptors: [], predicate:
                    NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [
                        NSPredicate(format: "id = %@", UserDefaults.standard.string(forKey: "userID")!),
                        NSPredicate(format: "isShared = %@", UserDefaults.standard.bool(forKey: "inAHousehold") ? "1" : "0") ]))
//                        NSPredicate(format: "isShared = 1")]))
    var currentUser: FetchedResults<User>
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "isShared == 1"))
    var users: FetchedResults<User>
    
    @State private var recipes: [Recipe] = []
    @State private var recipeOffset: Int = 3
    @State private var showHousehold: Bool = false
    @State private var showFilters: Bool = false
    @State private var appliedFilters: [Category] = []{
        didSet{
//            var filteredRecipes: [Recipe] = []
//            appliedFilters.forEach { filter in
//                let recipes = recipes.filter({ $0.isCategory(filter.id) })
//                filteredRecipes.append(contentsOf: recipes)
//                recipes.forEach { recipe in
//                    print("### recipe filtered: \(recipe.title)")
//                }
//            }
//            recipes = filteredRecipes
        }
    }
    
    private let shareCoordinator = ShareCoordinator()
    private var matches: [Recipe]{
        let matches = allRecipes.filter({ $0.likesCount == users.count })
        return matches
    }
    private var likes: [Recipe]{
        if let likes = currentUser.first?.likedRecipes?.allObjects as? [Recipe]{
            return likes
        }
        return []
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack{
                    LikesAndMatches(matches: matches,
                            likes: likes)
                    if !$appliedFilters.isEmpty{
                        ForEach(appliedFilters){ filter in
                            Text(filter.title)
//                        Text("Filter")
                                .frame(height: 45)
                                .padding([.leading, .trailing])
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                    }
                }
                
                .padding(.bottom)
                Spacer()
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
                        Image(systemName: "xmark").rejectStyle()
                    }
                    
                    Button(action: {
                        popRecipeStack(liked: true)
                    }) {
                        Text("✓").acceptStyle()
                    }
                }
                .padding(.top, 25)
            }
            .padding()
            .navigationTitle("Fryday")
            .navigationBarItems(
                trailing:
                    HStack(content: {
                        Button{
                            withAnimation {
                                showFilters = true
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .tint(.black)
                        }
                        Button{
                            withAnimation {
                                showHousehold = true
                            }
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .tint(.black)
                        }
                    })
            )
        }.overlay(alignment: .bottom) {
            if showHousehold{
                let dismiss = {
                    withAnimation {
                        showHousehold = false
                    }
                }
                Household(recipes: Array(allRecipes), 
                          users: Array(users),
                          dismissAction: dismiss)
            }
        }
        .sheet(isPresented: $showFilters, content: {
            let dismiss = {
                withAnimation {
                    showFilters = false
                }
            }
//            let applyFilter = { (filter: Category?) in if let filter{ _appliedFilters = [filter] }}
            Filters(appliedFilters: $appliedFilters, dismissAction: dismiss)
        })
        .ignoresSafeArea()
        .accentColor(.black)
        .onAppear(){
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
        if !UserDefaults.standard.bool(forKey: "appOpenedBefore"),
           allRecipes.isEmpty{
            Task{
                if let downloadedRecipes = try? await Webservice(context: moc).load (Recipe.all){
                    try! moc.save()
                    recipes = Array(downloadedRecipes.prefix(recipeOffset))
                    
                    createNewUser()
                    UserDefaults.standard.set(true, forKey: "appOpenedBefore")
                }
            }
        } else{
            guard let currentUser = currentUser.first else { return }
            
            let unseenRecipes = allRecipes.filter { recipe in
                let userLikesRecipe = currentUser.likedRecipes?.contains(recipe) ?? false
                let userDislikesRecipe = currentUser.dislikedRecipes?.contains(recipe) ?? false
                return !userLikesRecipe && !userDislikesRecipe
            }
            recipes = Array(unseenRecipes.prefix(recipeOffset))
            print("### allRecipes.count is \(allRecipes.count)")
//            recipeOffset += 2
        }
    }
    
    func popRecipeStack(liked: Bool, delayPop: Bool = true){
//1 - save the like/dislike
        handleUserPreference(recipeLiked: liked)
        checkIfMatch()
        
//2 - show swipe animation
        if delayPop{
            NotificationCenter.default.post(name: Notification.Name.swipeNotification,
                                            object: "Swiped", userInfo: ["swipeRight": liked])
        }
        
//3 - add + remove recipe
        DispatchQueue.main.asyncAfter(deadline: .now() + (delayPop ? 0.3 : 0.0)) {
            withAnimation {
                removeCard()
                addNewCard()
            }
        }
    }
    
    func handleUserPreference(recipeLiked liked: Bool){
        if let currentUser = currentUser.first,
           let recipe = recipes.last{
            guard let userAlreadyLikesRecipe = currentUser.likedRecipes?.contains(recipe) else { return }
            
            switch liked {
            case true:
                if !userAlreadyLikesRecipe{
                    recipe.likesCount += 1
                    
                    recipe.removeFromUserDislikes(currentUser)
                    currentUser.removeFromDislikedRecipes(recipe)
                }
                
                currentUser.likes(recipe)
                recipe.addToUser(currentUser)
            case false:
                if userAlreadyLikesRecipe{
                    recipe.likesCount -= 1
                    
                    recipe.removeFromUser(currentUser)
                    currentUser.removeFromLikedRecipes(recipe)
                }
                
                currentUser.dislikes(recipe)
                recipe.addToUserDislikes(currentUser)
            }
            
            try! moc.save() //change all try? to try! to find bugs
        }
    }
    
    func checkIfMatch(){
        if let recipe = recipes.last,
           users.count > 1,
           recipe.likesCount == users.count {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
    
    func createNewUser(){
        let user = User(context: moc)
        let userId: String = UserDefaults.standard.string(forKey: "userID")!
        user.id = userId
        user.name = "Not yet set"
        user.userType = 1
        user.isShared = false
        try! moc.save()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//MARK: -- Extractions

struct LikesAndMatches: View {
    var matches: [Recipe] = []
    var likes: [Recipe] = []
    
    var body: some View{
        HStack() {
            NavigationLink(
                destination: RecipesList(recipesType: "Matches",
                                         recipes: matches),
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
            Spacer()
        }
    }
}
