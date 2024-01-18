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
    
    
    @FetchRequest(fetchRequest: Vote.allVotes) var allVotes
    
//    @State private var recipeOffset: Int = 1
    @State private var showHousehold: Bool = false
    @State private var showFilters: Bool = false
    @State private var appliedFilters: [Category] = []
    
    private let shareCoordinator = ShareCoordinator()
    private var matches: [Recipe]{
        
        var recipesAndVotes: [Int64: Int] = [:] //** [RecipeIDs : VoteCount] **//
        var matches: [Int64] = []
        
        let likes = allVotes.filter({ $0.isLiked })
        for like in likes{
            let recipe = like.recipeId
            if let voteCount = recipesAndVotes[recipe]{
                let newVoteCount = voteCount + 1
                recipesAndVotes[recipe] = newVoteCount
                
                matches.append(recipe)
            } else{
                recipesAndVotes[recipe] = 1
            }
        }
        
        let uniqueRecipes = Set(matches)
        let recipes = recipeManager.getRecipesById(ids: Array(uniqueRecipes), fromContext: moc)
        return recipes ?? []
    }
    private var likes: [Recipe]{
        let votedRecipeIds = allVotes.filter({ $0.isLiked && $0.isCurrentUser }).map({ $0.recipeId })
        let recipes = recipeManager.getRecipesById(ids: votedRecipeIds, fromContext: moc)
        return recipes ?? []
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
            }
//            createNewUser()
            UserDefaults.standard.set(true, forKey: "appOpenedBefore")
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
//        guard let currentUser = currentUser.first,
              guard let recipe = recipeManager.recipe else { return }
//              let userAlreadyLikesRecipe = currentUser.likedRecipes?.contains(recipe) else { return }
        
//        switch liked {
//        case true:
//            if !userAlreadyLikesRecipe{
//                recipe.likesCount += 1
//                recipe.removeFromUserDislikes(currentUser)
//                currentUser.removeFromDislikedRecipes(recipe)
//            }
//            currentUser.likes(recipe)
//            recipe.addToUser(currentUser)
//            
//        case false:
//            if userAlreadyLikesRecipe{
//                recipe.likesCount -= 1
//                recipe.removeFromUser(currentUser)
//                currentUser.removeFromLikedRecipes(recipe)
//            }
//            currentUser.dislikes(recipe)
//            recipe.addToUserDislikes(currentUser)
//        }
        let userId: String = UserDefaults.standard.string(forKey: "userID")!
        
        let vote = Vote(context: moc)
        vote.isLiked = liked
        vote.date = Date.now
        vote.ownerId = userId
        vote.recipeId = recipe.recipeId
        
        if UserDefaults.standard.bool(forKey: "inAHousehold"),
           !UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
            if let existingShare = try? DataController.shared.persistentContainer.fetchShares(in: DataController.shared.sharedPersistentStore).first{
                
                DataController.shared.persistentContainer.share([vote], to: existingShare) { sharedObjectIds, ckShare, container, error in
                    if let sharedObjectIds{
                        print("### sharedObjectIds is: \(sharedObjectIds)")
                    }
                    if let ckShare{
                        print("### ckShare is: \(ckShare)")
                    }
                }
            }
            
//            DataController.shared.ckContainer.sharedCloudDatabase.fetch(withRecordID: <#T##CKRecord.ID#>, completionHandler: <#T##(CKRecord?, Error?) -> Void#>)
            
//            moc.assign(vote, to: DataController.shared.sharedPersistentStore)
        }
        
        try! moc.save()
        recipeManager.nextRecipe()
    }
    
//    func checkIfMatch(){
//        if let recipe = recipeManager.recipe,
//           users.count > 1,
//           recipe.likesCount == users.count {
//            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//        }
//    }
    
//    func createNewUser(){
//        let user = User(context: moc)
//        let userId: String = UserDefaults.standard.string(forKey: "userID")!
//        user.id = userId
//        user.name = "Not yet set"
//        user.userType = 1
////        user.isShared = false
//        try! moc.save()
//    }
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
