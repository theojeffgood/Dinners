//
//  Recipe+CoreDataProperties.swift
//  FryDay
//
//  Created by Theo Goodman on 11/2/23.
//
//

import Foundation
import CoreData


extension Recipe {
    
    @nonobjc 
    public class func fetchRequest(sort: [NSSortDescriptor] = [], predicate: NSPredicate? = nil) -> NSFetchRequest<Recipe> {
        let fetchRequest = NSFetchRequest<Recipe>(entityName: String(describing: Recipe.self))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sort
        fetchRequest.affectedStores = [DataController.shared.privatePersistentStore] // <<--THIS BREAKS LOAD OF RECIPES?? WTF
        return fetchRequest
    }
        
    static var allRecipesFetchRequest: NSFetchRequest<Recipe> {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest(sort: [])
        return request
    }

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
    func isAMatch() -> Bool{
        let householdCount: Int = UserDefaults.standard.integer(forKey: "householdCount")
        guard householdCount > 1,
              let ownerId = UserDefaults.standard.string(forKey: "userID"),
              let context = self.managedObjectContext else { return false }

        let voteSearch = NSPredicate(format: "recipeId == %d AND ownerId != %@", recipeId, ownerId)
        let request = Vote.fetchRequest(predicate: voteSearch)
        let votes = try! context.fetch(request)
        
        let likes = votes.filter({ $0.isLiked }).count
        guard likes != 0 else { return false }
        
        let isMatch = likes == (householdCount - 1) /* False positive for households of 3+ where only 2 likes. */
        return isMatch
    }
    
//    func isAMatch(with newVote: Vote) -> Bool{
//        guard newVote.isLiked,
//              let context = self.managedObjectContext else { return false }
//        
//        let recipePredicate = NSPredicate(format: "recipeId == %d AND ownerId != %@", recipeId, newVote.ownerId!)
//        let request = Vote.fetchRequest(predicate: recipePredicate)
//        let votes = try! context.fetch(request)
//        
//        let isMatch = !votes.isEmpty && votes.allSatisfy({ $0.isLiked })
//        return isMatch
//    }
}

//// MARK: Generated accessors for user
//extension Recipe {
//
//    @objc(addUserObject:)
//    @NSManaged public func addToUser(_ value: User)
//
//    @objc(removeUserObject:)
//    @NSManaged public func removeFromUser(_ value: User)
//
//    @objc(addUser:)
//    @NSManaged public func addToUser(_ values: NSSet)
//
//    @objc(removeUser:)
//    @NSManaged public func removeFromUser(_ values: NSSet)
//
//}
//
//// MARK: Generated accessors for userDislikes
//extension Recipe {
//
//    @objc(addUserDislikesObject:)
//    @NSManaged public func addToUserDislikes(_ value: User)
//
//    @objc(removeUserDislikesObject:)
//    @NSManaged public func removeFromUserDislikes(_ value: User)
//
//    @objc(addUserDislikes:)
//    @NSManaged public func addToUserDislikes(_ values: NSSet)
//
//    @objc(removeUserDislikes:)
//    @NSManaged public func removeFromUserDislikes(_ values: NSSet)
//
//}
//
//extension Recipe : Identifiable {
//
//}
