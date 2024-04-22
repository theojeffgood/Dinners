//
//  Recipe+CoreDataClass.swift
//  FryDay
//
//  Created by Theo Goodman on 11/1/23.
//
//

import CoreData
import CloudKit

class RecipeManager: NSObject, ObservableObject {
    
    @Published var recipe: Recipe?
    
    private var allRecipes: [Recipe]
    private var recipeIndex: Int
    private var categoryFilter: Category?
    
    var allVotes: [Vote]{
        didSet{
            for vote in allVotes{
                switch vote.isLiked {
                case true:
                    switch vote.isCurrentUser {
                    case true:
                        currentUserLikes.append(vote.recipeId)
                    case false:
                        householdLikes.append(vote.recipeId)
                    }
                case false:
                    dislikes.append(vote.recipeId)
                }
            }
        }
    }
    var currentUserLikes: [Int64]
    var householdLikes: [Int64]
    var dislikes: [Int64]
    
    private let votesController: NSFetchedResultsController<Vote>
    private let recipesController: NSFetchedResultsController<Recipe>
    private let context: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        context = managedObjectContext
        recipesController = NSFetchedResultsController(fetchRequest: Recipe.allRecipesFetchRequest,
                                                       managedObjectContext: context,
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
        votesController   = NSFetchedResultsController(fetchRequest: Vote.allVotes,
                                                       managedObjectContext: context,
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
        allRecipes = []
        recipeIndex = 0
        
        allVotes = []
        householdLikes = []
        currentUserLikes = []
        dislikes = []
        super.init()
        
        votesController.delegate   = self
        recipesController.delegate = self
        
        setValues()
    }
    
    func setValues(){
        do {
            try votesController.performFetch() // this must come before recipes. for filtering to work.
            try recipesController.performFetch()
            
            allVotes = votesController.fetchedObjects ?? []
            let recipes = recipesController.fetchedObjects ?? []
            
            allRecipes = filterRecipes(recipes)
            setRecipe(allRecipes.first)
            
        } catch {
            print("failed to fetch items!")
        }
    }
    
    func setRecipe(_ recipe: Recipe? = nil){
        DispatchQueue.main.async {
            self.recipe = recipe
        }
    }
}

extension RecipeManager: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        if case let recipes = controller.fetchedObjects as? [Recipe],
           recipes?.isEmpty == false{
            
            allRecipes = filterRecipes(recipes!)
            if allRecipes.indices.contains(recipeIndex),
               recipe == nil{
                setRecipe(allRecipes[recipeIndex])
            }
        }
        
        if case let votes = controller.fetchedObjects as? [Vote],
           votes?.isEmpty == false{
            
//            let newVotes = votes!.difference(from: allVotes)
            
            allVotes = votes!
            let recipes = allRecipes
            allRecipes = filterRecipes(recipes)
            
            if allRecipes.indices.contains(recipeIndex),
               recipe == nil{
                setRecipe(allRecipes[recipeIndex])
            }
        }
    }
}

extension RecipeManager{
    
    func filterRecipes(_ recipes: [Recipe]) -> [Recipe]{
        var filteredRecipes: [Recipe] = []
        
        for recipe in recipes {
            if !dislikes.contains(recipe.recipeId), // remove disliked recipes
               !currentUserLikes.contains(recipe.recipeId){ // remove already-liked recipes
                
                if let filterId = categoryFilter?.id,
                   !recipe.categories.contains(Int(filterId)){ continue } // apply category filter, if active
                
                let index = householdLikes.contains(recipe.recipeId) ? 0 : filteredRecipes.endIndex
                filteredRecipes.insert(recipe, at: index) // show likes first
            }
        }
        
        return filteredRecipes
    }
    
    @MainActor
    func nextRecipe(){
        recipeIndex += 1
        setRecipe(allRecipes[recipeIndex])
    }
    
    func getMatches() -> [Recipe]{
        guard UserDefaults.standard.bool(forKey: "inAHousehold") else { return [] }
        
        var matches: [Int64] = []
        for like in allVotes where like.isLiked{
            guard !matches.contains(like.recipeId),
                  allVotes.count(where: { $0.recipeId == like.recipeId }) > 1 /* householdCount */ else { continue }
            matches.append(like.recipeId)
        }
        
        return getRecipesById(ids: matches)
    }
    
    func getRecipesById(ids: [Int64]) -> [Recipe]?{
        let likesPredicate = NSPredicate(format: "recipeId IN %@", ids)
        let request = Recipe.fetchRequest(predicate: likesPredicate)
        let recipes = try? context.fetch(request)
        return recipes
    }
}

extension Collection {
    func count(where test: (Element) throws -> Bool) rethrows -> Int {
        return try self.filter(test).count
    }
}


extension RecipeManager{
    func applyFilter(_ filter: Category) {
        self.categoryFilter = filter
        resetRecipes()
    }
    
    func cancelFilter() {
        self.categoryFilter = nil
        resetRecipes()
    }

    func resetRecipes(){
        let request = Recipe.fetchRequest()
        let recipes = try! context.fetch(request)
        
        allRecipes = filterRecipes(recipes)
        recipeIndex = 0
        
        if allRecipes.indices.contains(recipeIndex){
//            recipe = allRecipes[recipeIndex]
            setRecipe(allRecipes[recipeIndex])
        }
    }
}
