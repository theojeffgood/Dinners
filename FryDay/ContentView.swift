//
//  ContentView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    
    @EnvironmentObject private var shareCoordinator: ShareCoordinator
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var recipeManager: RecipeManager
    
    @FetchRequest(fetchRequest: Vote.allVotes) var allVotes
    
    @State private var showHousehold: Bool = false
    @State private var showFilters: Bool = false
    @State private var appliedFilters: [Category] = []
    
    private var matches: [Recipe]{
        let matches = recipeManager.getMatches()
        return matches
    }
    private var likes: [Recipe]{
        let votedRecipeIds = allVotes.filter({ $0.isLiked && $0.isCurrentUser }).map({ $0.recipeId })
        let recipes = recipeManager.getRecipesById(ids: votedRecipeIds)
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
                        popRecipeStack(for: recipe,
                                       liked: liked,
                                       showSwipe: false)
                    }
//                    .transition(.opacity)
//                    .animation(.easeInOut(duration: 0.65), value: recipe)
                }
                
                
                Spacer()
                HStack(spacing: 65) {
                    Button(action: {
                        guard let recipe = recipeManager.recipe else { return }
                        popRecipeStack(for: recipe, liked: false, showSwipe: true)
                    }) {
                        Image(systemName: "xmark")
                            .rejectStyle()
                    }
                    
                    Button(action: {
                        guard let recipe = recipeManager.recipe else { return }
                        popRecipeStack(for: recipe, liked: true, showSwipe: true)
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
                Household(share: shareCoordinator.existingShare,
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
            print("###Recipe changed")
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//                NotificationCenter.default.post(name: Notification.Name.resetOffset,
//                                                object: nil, userInfo: nil )
//            }
        })
        
//---------SHOW JOINING-A-HOUSEHOLD ONBOARDING HERE
//        .onOpenURL { url in
//            print("referring url is: \(url)")
//        }
    }
}

extension ContentView{
    func popRecipeStack(for recipe: Recipe, liked: Bool, showSwipe: Bool){
            print("###Recording vote")
            let newVote = Vote(forRecipeId: recipe.recipeId, like: liked, in: moc)
            shareCoordinator.shareVoteIfNeeded(newVote) //1 of 2 (before moc.save)
            try! moc.save() //2 of 2 (after ck.share)
            if recipe.isAMatch(with: newVote){ celebrate() }
        
        if showSwipe{ // swipe animation //
            print("###Triggering swipe animation")
            NotificationCenter.default.post(name: Notification.Name.showSwipe,
                                            object: "Swiped", userInfo: ["swipeRight": liked])
        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + (showSwipe ? 0.15 : 0.0)) {
            print("###Switching to next recipe")
            recipeManager.nextRecipe()
//        }
    }
    
    func celebrate() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    func loadRecipes(){
        if !UserDefaults.standard.bool(forKey: "appOpenedBefore"){
            Task{
                try? await Webservice(context: moc).load (Recipe.all)
                try! moc.save()
            }
            UserDefaults.standard.set(true, forKey: "appOpenedBefore")
        }
    }
}

import CoreData

struct ContentView_Previews: PreviewProvider {
    static let entity = NSManagedObjectModel.mergedModel(from: nil)?.entitiesByName["Recipe"]
        
    static var previews: some View {
        let recipeOne = Recipe(entity: entity!, insertInto: nil)
        recipeOne.title = "Eggs and Bacon"
        recipeOne.imageUrl = "https://halflemons-media.s3.amazonaws.com/787.jpg"
        
        let moc = DataController.shared.context
        let recipeManager = RecipeManager(managedObjectContext: moc)
        recipeManager.recipe = recipeOne
        
        return ContentView(recipeManager: recipeManager)
    }
}
