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
            recipe = allRecipes.first
            
        } catch {
            print("failed to fetch items!")
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
                recipe = allRecipes[recipeIndex]
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
                recipe = allRecipes[recipeIndex]
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
    
    func nextRecipe(){
        recipeIndex += 1
        recipe = allRecipes[recipeIndex]
    }
    
    func getMatches() -> [Recipe]{
        guard UserDefaults.standard.bool(forKey: "inAHousehold") else { return [] }
        
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
        let recipes = getRecipesById(ids: Array(uniqueRecipes))
        return recipes ?? []
    }
    
    func getRecipesById(ids: [Int64]) -> [Recipe]?{
        let likesPredicate = NSPredicate(format: "recipeId IN %@", ids)
        let request = Recipe.fetchRequest(predicate: likesPredicate)
        let recipes = try? context.fetch(request)
        return recipes
    }
}

extension RecipeManager{
    func applyFilter(_ filter: Category? = nil) {
        
        if let filter{
            self.categoryFilter = filter
        } else{
            self.categoryFilter = nil
        }
        
        let request = Recipe.fetchRequest()
        let recipes = try! context.fetch(request)
        
        allRecipes = filterRecipes(recipes)
        recipeIndex = 0
        
        if allRecipes.indices.contains(recipeIndex){
            recipe = allRecipes[recipeIndex]
        }
    }
}
