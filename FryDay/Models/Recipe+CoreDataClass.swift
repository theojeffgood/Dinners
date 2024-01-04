//
//  Recipe+CoreDataClass.swift
//  FryDay
//
//  Created by Theo Goodman on 11/1/23.
//
//

import Foundation
import CoreData


//public class Recipe: NSManagedObject {
//    
//}

extension Recipe {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Recipe> {
        return NSFetchRequest<Recipe>(entityName: String(describing: Recipe.self))
    }
    
  static var allRecipesFetchRequest: NSFetchRequest<Recipe> {   
      let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
      request.predicate = NSPredicate(format: "isShared == %d",
                                      UserDefaults.standard.bool(forKey: "inAHousehold"))
//                                      predicate: NSPredicate(format: "userDislikes.@count == 0")))
      
      request.sortDescriptors = [NSSortDescriptor(key: "isLiked", ascending: false)]
//                                 NSSortDescriptor(key: "recipeId", ascending: true)
//                                 NSSortDescriptor(keyPath: \Recipe.recipeId, ascending: true)]
      
      return request
  }
}

class RecipeManager: NSObject, ObservableObject {
    
    @Published var recipe: Recipe?
    var allRecipes: [Recipe]
    
    var currentUser: User?
//    @Published var recipe: Recipe?
    private let recipesController: NSFetchedResultsController<Recipe>
    private let usersController: NSFetchedResultsController<User>
    
    init(managedObjectContext: NSManagedObjectContext) {
        recipesController = NSFetchedResultsController(fetchRequest: Recipe.allRecipesFetchRequest,
                                                       managedObjectContext: managedObjectContext,
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
        usersController = NSFetchedResultsController(fetchRequest: User.currentUserFetchRequest,
                                                       managedObjectContext: managedObjectContext,
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
        allRecipes = []
        super.init()
        
        recipesController.delegate = self
        usersController.delegate = self
        
        do {
            try recipesController.performFetch()
            try usersController.performFetch()
            
            currentUser = usersController.fetchedObjects?.first
            let recipes = recipesController.fetchedObjects ?? []
            
            let unseenRecipes = filterRecipes(recipes)
            allRecipes = unseenRecipes
            recipe = unseenRecipes.first
            
        } catch {
            print("failed to fetch items!")
        }
    }
    
    func filterRecipes(_ recipes: [Recipe]) -> [Recipe]{
        let unseenRecipes = recipes.filter { recipe in
            let userLikesRecipe = currentUser?.likedRecipes?.contains(recipe) ?? false
            let userDislikesRecipe = currentUser?.dislikedRecipes?.contains(recipe) ?? false
            return !userLikesRecipe && !userDislikesRecipe
        }
        return unseenRecipes
    }
}

extension RecipeManager: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if case let recipes = controller.fetchedObjects as? [Recipe],
           recipes?.isEmpty == false{
            let unseenRecipes = filterRecipes(recipes!)
            allRecipes = unseenRecipes
            recipe = unseenRecipes.first
        }
        
        if case let users = controller.fetchedObjects as? [User],
           users?.isEmpty == false{
            currentUser = users!.first!
        }
    }
}
