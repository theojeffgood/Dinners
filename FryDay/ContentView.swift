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
    @ObservedObject var recipeManager: RecipeManager
    
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
    
//    @State private var recipeOffset: Int = 1
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
            let matches = recipeManager.allRecipes.filter({ $0.likesCount == users.count })
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
                if let recipe = recipeManager.recipe{
                    RecipeCardView(recipe: recipe){ liked in
                        popRecipeStack(liked: liked, delayPop: false)
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
                Household(recipes: recipeManager.allRecipes,
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
        .onAppear(){ loadRecipes() }
        .onChange(of: recipeManager.recipe, perform: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                NotificationCenter.default.post(name: Notification.Name.resetOffset,
                                                object: nil, userInfo: nil )
            }
        })
        
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
                
                createNewUser()
                UserDefaults.standard.set(true, forKey: "appOpenedBefore")
            }
        }
    }
    
    func popRecipeStack(liked: Bool, delayPop: Bool = true){
//1 - save the like/dislike
        DispatchQueue.main.asyncAfter(deadline: .now() + (delayPop ? 0.15 : 0.0)) {
            handleUserPreference(recipeLiked: liked)
        }
//        checkIfMatch()
        
//2 - show swipe animation
        if delayPop{
            NotificationCenter.default.post(name: Notification.Name.swipeNotification,
                                            object: "Swiped", userInfo: ["swipeRight": liked])
        }
    }
    
    func handleUserPreference(recipeLiked liked: Bool){
        guard let currentUser = currentUser.first,
              let recipe = recipeManager.recipe,
              let userAlreadyLikesRecipe = currentUser.likedRecipes?.contains(recipe) else { return }
        
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
    
//    func checkIfMatch(){
//        if let recipe = recipes.last,
//           users.count > 1,
//           recipe.likesCount == users.count {
//            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//        }
//    }
    
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

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

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
