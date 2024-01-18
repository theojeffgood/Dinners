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
    @State private var existingShare: CKShare?
    @ObservedObject var recipeManager: RecipeManager
    
    @FetchRequest(fetchRequest: Vote.allVotes) var allVotes
    
    @State private var showHousehold: Bool = false
    @State private var showFilters: Bool = false
    @State private var appliedFilters: [Category] = []
    
//    private let shareCoordinator = ShareCoordinator()
    private var matches: [Recipe]{
        let matches = recipeManager.getMatches(inContext: moc)
        return matches
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
        .onAppear(){
            if UserDefaults.standard.bool(forKey: "inAHousehold"),
               !UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
                self.existingShare = try? DataController.shared.persistentContainer.fetchShares(in: DataController.shared.sharedPersistentStore).first
            }
        }
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
            UserDefaults.standard.set(true, forKey: "appOpenedBefore")
        }
    }
    
    func popRecipeStack(liked: Bool, delayPop: Bool = true){
//1 - save the like/dislike
        DispatchQueue.main.asyncAfter(deadline: .now() + (delayPop ? 0.15 : 0.0)) {
            handleUserPreference(recipeLiked: liked)
        }
        
//2 - show swipe animation
        if delayPop{
            NotificationCenter.default.post(name: Notification.Name.swipeNotification,
                                            object: "Swiped", userInfo: ["swipeRight": liked])
        }
        
        recipeManager.nextRecipe()
    }
    
    func handleUserPreference(recipeLiked liked: Bool){
        guard let recipe = recipeManager.recipe else { return }
        
        let userId: String = UserDefaults.standard.string(forKey: "userID")!
        let vote = Vote(context: moc)
        vote.isLiked = liked
        vote.date = Date.now
        vote.ownerId = userId
        vote.recipeId = recipe.recipeId
        checkIfMatch(vote: vote)
        
        if UserDefaults.standard.bool(forKey: "inAHousehold"),
           !UserDefaults.standard.bool(forKey: "isHouseholdOwner"),
           let existingShare{
            
            DataController.shared.persistentContainer.share([vote], to: existingShare) { _, _, _, error in
                if let error{ fatalError("### failed to share vote: \(error)") }
            }
        }
        
        try! moc.save()
    }
    
    func checkIfMatch(vote newVote: Vote){
        guard newVote.isLiked else { return }
        let existingVotes = allVotes.filter({ existingVote in
            existingVote.recipeId == newVote.recipeId &&
            existingVote.ownerId != newVote.ownerId
        })
        guard !existingVotes.isEmpty else { return }
        if existingVotes.allSatisfy({ $0.isLiked }){
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
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
