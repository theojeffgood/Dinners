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
    
    @State private var playConfetti = false
    @State private var showTabbar: Bool = true
    @State private var showHousehold: Bool = false
    
    @State private var showFilters: Bool = false
    @State private var allFilters: [Category] = []
    @State private var appliedFilters: [Category] = []
    @State private var filterIsActive: Bool = false
    @State private var activeFilter: Category? = nil
    
    var body: some View {
        NavigationStack{
            NavigationLink {
                if let recipe = recipeManager.recipe{
                    RecipeDetailsView(recipe: recipe,
                                      recipeTitle: recipe.title!)
                    .onAppear(perform: {
                        withAnimation { showTabbar = false }
                    })
                }
            } label: {
                VStack {
                    if !$appliedFilters.isEmpty{
                        HStack {
                            Text("Filters: ")
                            
                            ScrollView(.horizontal){
                                HStack {
                                    let items: [Category] = filterIsActive ? [activeFilter!] : appliedFilters
                                    ForEach(items){ item in
                                        Button {
                                            withAnimation{
                                                filterIsActive.toggle()
                                                self.activeFilter = filterIsActive ? item : nil
                                                recipeManager.applyFilter(activeFilter)
                                            }
                                        } label: {
                                            Text(item.title + (filterIsActive ? "  X" : ""))
                                                .frame(height: 40)
                                                .padding([.leading, .trailing])
                                                .overlay( RoundedRectangle(cornerRadius: 5).stroke(.black, lineWidth: 1) )
                                                .padding([.top, .bottom], 1)
                                        }
                                    }
                                    Spacer()
                                }.padding(.leading, 1)
                            }.scrollIndicators(.never)
                        }
                        .padding(.leading, 10)
                        .padding([.top, .bottom], 5)
                    }
                    if let recipe = recipeManager.recipe{
                        ZStack(alignment: .center) {
                            RecipeCardView(recipe: recipe){ liked in
                                popRecipeStack(for: recipe, liked: liked, showSwipe: false)
                            }
                            if playConfetti{
                                CelebrationView(name: "Confetti",
                                                play: $playConfetti)
                                .id(1) // swiftui unique-ness thing
                                .allowsHitTesting(false)
                            }
                            
                            HStack() {
                                VStack(alignment: .trailing) {
                                    Button(action: { popRecipeStack(for: recipe, liked: false) }) {
                                        VStack {
                                            Image(systemName: "arrow.turn.up.left")
                                                .resizable()
                                                .tint(.white)
                                                .frame(width: 75, height: 75)
                                            Text("Nay!")
                                                .foregroundColor(.white)
                                                .font(.title)
                                        }
                                    }
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Button(action: { popRecipeStack(for: recipe, liked: true) }) {
                                        VStack {
                                            Image(systemName: "arrow.turn.up.right")
                                                .resizable()
                                                .tint(.white)
                                                .frame(width: 75, height: 75)
                                            Text("Yay!")
                                                .foregroundColor(.white)
                                                .font(.title)
                                        }
                                    }
                                }
                            }
                            .padding([.leading, .trailing], 3)
                        }
                    }
                }
                .padding([.leading, .bottom, .trailing], 5)
                .toolbar(showTabbar ? .visible : .hidden, for: .tabBar)
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
                                    showTabbar = false
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
                    Household(share: shareCoordinator.existingShare, onDismiss: {
                        withAnimation {
                            showTabbar = true
                            showHousehold = false
                        }
                    })
                }
            }.sheet(isPresented: $showFilters, onDismiss: { loadFilters() }, content: {
//                Filters(appliedFilters: $appliedFilters)
                Filters()
            }).onAppear(){
                loadRecipes()
                showTabbar = true
                
                loadFilters()
            }
        }
    }
}

extension ContentView{
    func loadFilters(){
        allFilters = Category.allCategories(in: moc)
        appliedFilters = allFilters.filter({ $0.isPurchased })
    }
    
    func popRecipeStack(for recipe: Recipe, liked: Bool, showSwipe: Bool = true){
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (showSwipe ? 0.15 : 0.0)) {
            print("###Switching to next recipe")
            recipeManager.nextRecipe()
        }
    }
    
    func celebrate() {
        playConfetti = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    func loadRecipes(){
        if !UserDefaults.standard.bool(forKey: "appOpenedBefore"){
            Task{
                try? await Webservice(context: moc).load (Recipe.all)
                try? await Webservice(context: moc).load (Category.all)
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
