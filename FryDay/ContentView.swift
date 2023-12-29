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
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "isLiked", ascending: false),
                                    NSSortDescriptor(key: "recipeId", ascending: true)],
//                  predicate: NSPredicate(format: "userDislikes.@count == 0"))
                  predicate: NSPredicate(format: "isShared == %d",
                                         UserDefaults.standard.bool(forKey: "inAHousehold")))
    var allRecipes: FetchedResults<Recipe>
    @FetchRequest(sortDescriptors: [], predicate:
                    NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [
                        NSPredicate(format: "id = %@",
                                    UserDefaults.standard.string(forKey: "userID")!),
                        NSPredicate(format: "isShared == %d",
                                    UserDefaults.standard.bool(forKey: "inAHousehold")) ]))
    var currentUser: FetchedResults<User>
    
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "isShared == %d",
                                                              UserDefaults.standard.bool(forKey: "inAHousehold")))
    var users: FetchedResults<User>
    
    @State private var recipeOffset: Int = 1
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
        if users.count > 1{
            let matches = allRecipes.filter({ $0.likesCount == users.count })
            return matches
        }
        return []
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
                                .frame(height: 45)
                                .padding([.leading, .trailing])
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                    }
                }.padding(.bottom, 5)
                
                Spacer()
                ZStack {
                    ForEach(allRecipes[min(allRecipes.endIndex, recipeOffset - 1) ..< min(allRecipes.endIndex, recipeOffset)], id: \.self) { recipe in
                        RecipeCardView(recipe: recipe,
                                       isTopRecipe: (true)){ liked, _ in
                            popRecipeStack(liked: liked, delayPop: false)
                        }
                    }
                }
                Spacer()
                //ACTION BUTTONS
                HStack(spacing: 65) {
                    Button(action: {
                        popRecipeStack(liked: false)
                    }) {
                        Image(systemName: "xmark")
                            .rejectStyle()
                    }
                    
                    Button(action: {
                        popRecipeStack(liked: true)
                    }) {
                        Text("✓")
                            .acceptStyle()
                    }
                }
                .padding(.top, 5)
            }
            .padding(5)
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
        }.sheet(isPresented: $showFilters, content: {
            let dismiss = {
                withAnimation {
                    showFilters = false
                }
            }
            Filters(appliedFilters: $appliedFilters,
                    dismissAction: dismiss)
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
        if !UserDefaults.standard.bool(forKey: "appOpenedBefore"){
        Task{
            try? await Webservice(context: moc).load (Recipe.all)
            try! moc.save()
            
//            if !UserDefaults.standard.bool(forKey: "appOpenedBefore"){
                createNewUser()
                UserDefaults.standard.set(true, forKey: "appOpenedBefore")
            }
        }
//            let unseenRecipes = allRecipes.filter { recipe in
//                let userLikesRecipe = currentUser.likedRecipes?.contains(recipe) ?? false
//                let userDislikesRecipe = currentUser.dislikedRecipes?.contains(recipe) ?? false
//                return !userLikesRecipe && !userDislikesRecipe
//            }
//            recipes = Array(unseenRecipes.prefix(recipeOffset))
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
                recipeOffset += 1
            }
        }
    }
    
    func handleUserPreference(recipeLiked liked: Bool){
        guard let currentUser = currentUser.first,
              allRecipes.indices.contains(recipeOffset - 1) else { return }
        let recipe = allRecipes[recipeOffset - 1]
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
        
        try! moc.save()
    }
    
    func checkIfMatch(){
//        if let recipe = recipes.last,
//           users.count > 1,
//           recipe.likesCount == users.count {
//            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//        }
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
