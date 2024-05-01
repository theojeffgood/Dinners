//
//  Recipe.swift
//  FryDay
//
//  Created by Theo Goodman on 11/2/23.
//
//

import CoreData

extension Recipe {

    @NSManaged public var cooktime: String?
    @NSManaged public var id: UUID?
    @NSManaged public var imageUrl: String?
    @NSManaged public var ingredients: [Int]?
    @NSManaged public var categories: [Int]
    @NSManaged public var recipeId: Int64
    @NSManaged public var recipeStatusId: Int16
    @NSManaged public var source: String?
    @NSManaged public var title: String?
    @NSManaged public var websiteUrl: String?

    @MainActor
    func isAMatch(with householdLikes: [Int64]) -> Bool{
        guard UserDefaults.standard.bool(forKey: "inAHousehold") else { return false }
        
        let numOfParticipants = UserDefaults.standard.integer(forKey: "householdCount")
        if  numOfParticipants == 1 { return false }
        
        let recipeLikes = householdLikes.filter({ $0 == self.recipeId })
        guard !recipeLikes.isEmpty else { return false }
        
        let matchThreadshold = recipeLikes.count + 1
        let isMatch = (matchThreadshold == numOfParticipants)
        
        return isMatch
    }
    
    func isCategory(_ category: Category?) -> Bool{
        guard let category else { return false }
        return self.categories.contains( Int( category.id ) )
    }
}

extension Recipe{
    
    @nonobjc
    public class func fetchRequest(sort: [NSSortDescriptor] = [], predicate: NSPredicate? = nil) -> NSFetchRequest<Recipe> {
        let fetchRequest = NSFetchRequest<Recipe>(entityName: String(describing: Recipe.self))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sort
        fetchRequest.affectedStores = [DataController.shared.privateStore] // <<--THIS BREAKS LOAD OF RECIPES?? WTF
        return fetchRequest
    }
        
    static var allRecipes: NSFetchRequest<Recipe> {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest(sort: [])
        return request
    }
}
