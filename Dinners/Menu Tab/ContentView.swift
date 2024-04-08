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
    @ObservedObject var filterManager: FilterManager
    
    @State private var hapticsHelper = HapticsHelper()
    @State private var playConfetti = false
    @State private var showFilters: Bool = false
    @State private var showTabbar: Bool = true
    
    @State private var showModal = false
    @State private var offset = CGSize.zero
    @State private var recipeCardOpacity = 1.0
    
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
                VStack{
                    FiltersBar(filterIsActive: $filterManager.filterIsActive,
                               showFilters: $showFilters,
                               items: $filterManager.appliedFilters){ item in
                        filterManager.toggleFilter(item)
                        filterManager.filterIsActive ?
                        recipeManager.applyFilter(item) : recipeManager.cancelFilter()
                    }.padding(.bottom, 15)
                    
                    if let recipe = recipeManager.recipe{
                        ZStack(alignment: .center) {
                            RecipeCardView(recipe: recipe)
                                .opacity(recipeCardOpacity)
                                .offset(x: offset.width, y: offset.height * 0.85)
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            offset = gesture.translation
                                        }
                                        .onEnded { _ in
                                            if abs(offset.width) > 100 {
                                                animateCardAway(recipe, offset: offset)
                                            } else {
                                                // Reset position if not swiped far enough
                                                withAnimation(.spring) {
                                                    offset = .zero
                                                }
                                            }
                                        }
                                )
                            
                            if showModal{
                                MatchView()
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            withAnimation { showModal = false }
                                        }
                                    }
                            }
                            if playConfetti{
                                CelebrationView("Confetti", play: $playConfetti)
                                    .id(recipe.recipeId) // swiftui unique-ness thing
                                    .allowsHitTesting(false)
                            }
                            ActionButtons() { liked in
                                switch liked{
                                case true:
                                    animateCardAway(recipe, offset: CGSize(width: 300, height: 0))
                                case false:
                                    animateCardAway(recipe, offset: CGSize(width: -300, height: 0))
                                    
                                }
                            }
                        }
                    }
                }.padding(10)
                
                    .toolbar(showTabbar ? .visible : .hidden, for: .tabBar)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("DINNERS").font(.custom("Solway-Regular", size: 24))
                                .foregroundStyle(.black)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(isPresented: $showFilters, content: {
                Filters(allCategories: filterManager.allFilters)
            })
            .onAppear(){
                loadRecipes()
                showTabbar = true
                recipeCardOpacity = 1.0
                hapticsHelper.prepareHaptics()
            }
        }
    }
}

extension ContentView{
    
    func animateCardAway(_ recipe: Recipe, offset direction: CGSize) {
        let liked = (direction.width > 0)

        withAnimation(.linear(duration: 0.20)) {
            offset = CGSize(width: direction.width * 4, height: direction.height * 4)
            recipeCardOpacity = 0.0001 // does this help / prevent smooth transition of recipes?
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            offset = .zero
            recipeManager.nextRecipe()
            
            Task {
                await castVote(recipe, was: liked)
            }
            
            var isMatch = false
            if liked{
                isMatch = recipe.isAMatch()
                if isMatch{ celebrate() }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (isMatch ? 1.75 : 0.675)) {
                withAnimation(.linear(duration: 0.2)) {
                    recipeCardOpacity = 1.0
                }
            }
        }
    }
    
    func castVote(_ recipe: Recipe, was liked: Bool) async{
        Task{
            let newVote = Vote(forRecipeId: recipe.recipeId, like: liked, in: moc)
            await ShareCoordinator.shared.shareIfNeeded(newVote) //1 of 2 (before moc.save)
            try! moc.save() //2 of 2 (after ck.share)
        }
    }
    
    func celebrate() {
        hapticsHelper.complexSuccess()
        playConfetti = true
        showModal = true
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
        
        let filterManager = FilterManager(managedObjectContext: moc)
        
        return ContentView(recipeManager: recipeManager, filterManager: filterManager)
    }
}

