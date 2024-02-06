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
    var allRecipes: [Recipe]
    private var recipeIndex: Int
    private var categoryFilter: Category?
    
    var allVotes: [Vote]{
        didSet{
            currentUserLikes = allVotes.filter({ $0.isLiked && $0.isCurrentUser }).map({ $0.recipeId })
            householdLikes = allVotes.filter({ $0.isLiked && !$0.isCurrentUser }).map({ $0.recipeId })
            dislikes = allVotes.filter({ !$0.isLiked }).map({ $0.recipeId })
        }
    }
    var currentUserLikes: [Int64]
    var householdLikes: [Int64]
    var dislikes: [Int64]
    
    private let recipesController: NSFetchedResultsController<Recipe>
    private let votesController: NSFetchedResultsController<Vote>
//    private let categoriesController: NSFetchedResultsController<Category>
    
    private let context: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        recipesController      = NSFetchedResultsController(fetchRequest: Recipe.allRecipesFetchRequest,
                                                       managedObjectContext: managedObjectContext,
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
        votesController        = NSFetchedResultsController(fetchRequest: Vote.allVotes,
                                                       managedObjectContext: managedObjectContext,
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
//        categoriesController   = NSFetchedResultsController(fetchRequest: Category.fetchRequest(),
//                                                       managedObjectContext: managedObjectContext,
//                                                       sectionNameKeyPath: nil, cacheName: nil)
        
        allRecipes = []
        recipeIndex = 0
        
        allVotes = []
        householdLikes = []
        currentUserLikes = []
        dislikes = []
        
        context = managedObjectContext
        super.init()
        
        recipesController.delegate    = self
        votesController.delegate      = self
//        categoriesController.delegate = self
        
        setValues()
    }
    
    func setValues(){
        do {
//            try categoriesController.performFetch()
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

            allVotes = votes!
            let recipes = allRecipes
            allRecipes = filterRecipes(recipes)
            
            if allRecipes.indices.contains(recipeIndex),
               recipe == nil{
                recipe = allRecipes[recipeIndex]
            }
        }
        
//        if case let categories = controller.fetchedObjects as? [Category],
//           categories?.isEmpty == false{
//
//            print("### categories changed")
//        }
    }
}

extension RecipeManager{
    
    func filterRecipes(_ recipes: [Recipe]) -> [Recipe]{
        let removeAnyDislikes = recipes.filter({ !dislikes.contains($0.recipeId) })
        var removeOldLikes = removeAnyDislikes.filter({ !currentUserLikes.contains($0.recipeId) })
        
        if let filterId = categoryFilter?.id{
            removeOldLikes.removeAll(where: { !$0.categories.contains(Int(filterId)) })
        }
        
        removeOldLikes.sort(by: { householdLikes.contains($0.recipeId) && !householdLikes.contains($1.recipeId) })
        return removeOldLikes
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
        print("###applying filters:\(filter)")
        
        if let filter{
            self.categoryFilter = filter
        } else{
            self.categoryFilter = nil
        }
        
        let recipes = allRecipes
        allRecipes = filterRecipes(recipes)
//        recipeIndex = 0
        
        if allRecipes.indices.contains(recipeIndex){
            recipe = allRecipes[recipeIndex]
        }
    }
}
