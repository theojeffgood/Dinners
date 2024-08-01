//
//  Recipe+CoreDataClass.swift
//  FryDay
//
//  Created by Theo Goodman on 11/1/23.
//
//

import CoreData
import CloudKit
import OSLog

class RecipeManager: NSObject, ObservableObject {
    
    @Published var recipe: Recipe?
    @Published var recipes: [Recipe] = []
    
    var matches: [Recipe] = []{
        didSet{
            if recipeType == .matches {
                recipes = matches
            }
        }
    }
    var recipeType: RecipeType = .matches{
        didSet{
            switch recipeType {
            case .matches:
                getMatches()
                recipes = matches
                
            case .likes:
                recipes = getRecipesById( userLikes )
            }
        }
    }
    
    private var allRecipes: [Recipe] = []
    private var activeFilter: Category?
    private var filterIsActive: Bool{ activeFilter != nil }
    
    private var allVotes: [Vote] = []
    private var userLikes: [Int64] = []
    var householdLikes: [Int64] = [] // important: do not de-dupe. see: recipes match algo.
    private var dislikes: [Int64] = []
    
    private let votesController: NSFetchedResultsController<Vote>
    private let recipesController: NSFetchedResultsController<Recipe>
    private let context: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        context = managedObjectContext
        recipesController = NSFetchedResultsController(fetchRequest: Recipe.allRecipes, 
                                                       managedObjectContext: context,
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
        votesController   = NSFetchedResultsController(fetchRequest: Vote.allVotes,
                                                       managedObjectContext: context, 
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
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
            processVotes( allVotes )
            let recipes = recipesController.fetchedObjects ?? []
            
            allRecipes = filterRecipes(recipes)
            nextRecipe()
            
        } catch { Logger.recipe.error("Failed to fetch recipes / votes!") }
    }
    
    func nextRecipe(){
        guard !allRecipes.isEmpty else { return }
        
        let recipe = allRecipes.removeFirst()
        DispatchQueue.main.async {
            self.recipe = recipe
        }
        allRecipes.append(recipe)
    }
}

extension RecipeManager: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let recipes = controller.fetchedObjects as? [Recipe], !recipes.isEmpty{
            allRecipes = filterRecipes( recipes )
            if recipe.isNil{ nextRecipe() }
        }
        
        if let votes = controller.fetchedObjects as? [Vote], !votes.isEmpty{
            var possibleNewMatches = false
            let newVotes = findNewVotes(in: votes, &possibleNewMatches)
            processVotes(newVotes)
            
            allVotes   = votes
            allRecipes = filterRecipes()
            
            if possibleNewMatches{ getMatches() }
            if recipe.isNil{ nextRecipe() }
        }
    }
}

extension RecipeManager{
    func filterRecipes(_ recipes: [Recipe]? = nil) -> [Recipe]{
        var filteredRecipes: [Recipe] = []
        
        for recipe in recipes ?? self.allRecipes {
            guard  !dislikes.contains(recipe.recipeId),                  // exclude disliked recipes
                  !userLikes.contains(recipe.recipeId) else { continue } // exclude already-liked recipes
            
            if filterIsActive && !recipe.category(is: activeFilter){ continue } // apply filter
            
            let isLiked = householdLikes.contains(recipe.recipeId)
            filteredRecipes.insert(recipe, at: isLiked ? 0 : filteredRecipes.endIndex) // show likes first
        }
        
        return filteredRecipes
    }
    
    func getMatches(){
        guard UserDefaults.standard.bool(forKey: "inAHousehold") else { return }
        Logger.recipe.log("###Refresh matches on Thread.isMain?: \(Thread.isMainThread)")
        
        let numOfParticipants = UserDefaults.standard.integer(forKey: "householdCount")
        if  numOfParticipants == 1 { return }
        
        var matchIds: [Int64] = []
        for like in userLikes{
            let likeCount = householdLikes.count(where: { $0 == like })
            if  likeCount + 1 == numOfParticipants{ matchIds.append(like) }
        }
        
        self.matches = getRecipesById( matchIds )
    }
    
    private func getRecipesById(_ ids: [Int64]) -> [Recipe]{
        let likesPredicate = NSPredicate(format: "recipeId IN %@", ids)
        let request = Recipe.fetchRequest(predicate: likesPredicate)
        let recipes = try! context.fetch(request)
        
        var dedupedRecipes: [Recipe] = []
        for recipe in recipes {
            guard !dedupedRecipes.contains(where: { $0.recipeId == recipe.recipeId }) else { continue }
            dedupedRecipes.append(recipe)
        }
            
        return dedupedRecipes
    }
}


extension RecipeManager{
    func applyFilter(_ filter: Category) {
        self.activeFilter = filter
        resetRecipes()
    }
    
    func cancelFilter() {
        self.activeFilter = nil
        resetRecipes()
    }

    func resetRecipes(){
        let request = Recipe.fetchRequest()
        let recipes = try! context.fetch(request)
        allRecipes = filterRecipes(recipes)
        
        nextRecipe()
    }
}

//MARK: -- VOTE HANDLING --

extension RecipeManager{
    func processVotes(_ allVotes: [Vote]){
        for vote in allVotes{
            switch vote.isLiked {
            case true:
                
                switch vote.isCurrentUser {
                case true:
                    userLikes.append(vote.recipeId)
                case false:
                    householdLikes.append(vote.recipeId)
                }
                
            case false:
                dislikes.append(vote.recipeId)
            }
        }
    }
    
    func findNewVotes(in votes: [Vote], _ possibleNewMatches: inout Bool) -> [Vote]{
        let diffs = votes.difference(from: allVotes).inferringMoves() // if #available(iOS 9999, *){
        
        var newVotes: [Vote] = []
        for change in diffs {
            guard case let .insert(_, newVote, move) = change, move.isNil else { continue }
            Logger.sharing.log("###Vote cast for rID: \(newVote.recipeId) by currentUser: \(newVote.isCurrentUser)")
            
            newVotes.append( newVote )
            if newVote.isImportant{ possibleNewMatches = true }
        }
        return newVotes
    }
}

extension RecipeManager{
    func deleteVote(for recipe: Recipe){
        guard let vote = allVotes.first(where: { $0.recipeId == recipe.recipeId && $0.isCurrentUser }) else { return }
        vote.isLiked = false
        try! context.save()
        
        userLikes.removeAll(where: { $0 == vote.recipeId })
        dislikes.append(vote.recipeId)
        recipeType = .likes // Triggers UI refresh on Likes list        
    }
}
