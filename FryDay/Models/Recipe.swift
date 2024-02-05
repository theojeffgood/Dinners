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
    
    @nonobjc public class func fetchRequest(sort: [NSSortDescriptor] = [], predicate: NSPredicate? = nil) -> NSFetchRequest<Recipe> {
        let fetchRequest = NSFetchRequest<Recipe>(entityName: String(describing: Recipe.self))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sort
//        return fetchRequest
        
        if UserDefaults.standard.bool(forKey: "inAHousehold") &&
           !UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
            fetchRequest.affectedStores = [DataController.shared.sharedPersistentStore]
        }
        
        return fetchRequest
    }
        
    static var allRecipesFetchRequest: NSFetchRequest<Recipe> {
//        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest(sort: [NSSortDescriptor(key: "isLiked", ascending: false)])
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest(sort: [])
//                                                                  predicate: NSPredicate(format: "isShared == %d",
//                                                                                         UserDefaults.standard.bool(forKey: "inAHousehold"))
//        )
        return request
        
//        request.predicate = NSPredicate(format: "isShared == %d",
//                                        UserDefaults.standard.bool(forKey: "inAHousehold"))
//    predicate: NSPredicate(format: "userDislikes.@count == 0")))
//
//        request.sortDescriptors = [NSSortDescriptor(key: "isLiked", ascending: false)]
//        NSSortDescriptor(key: "recipeId", ascending: true)
//        NSSortDescriptor(keyPath: \Recipe.recipeId, ascending: true)]
    }

    @NSManaged public var cooktime: String?
    @NSManaged public var id: UUID?
    @NSManaged public var imageUrl: String?
    @NSManaged public var ingredients: [Int]?
    @NSManaged public var categories: [Int]
//    @NSManaged public var isLiked: Bool
//    @NSManaged public var isShared: Bool
    @NSManaged public var recipeId: Int64
    @NSManaged public var recipeStatusId: Int16
//    @NSManaged public var likesCount: Int32
    @NSManaged public var source: String?
    @NSManaged public var title: String?
    @NSManaged public var websiteUrl: String?
//    @NSManaged public var user: NSSet?
//    @NSManaged public var userDislikes: NSSet?

    func isAMatch(with newVote: Vote) -> Bool{
        guard newVote.isLiked,
              let context = self.managedObjectContext else { return false }
        
        let recipePredicate = NSPredicate(format: "recipeId == %d AND ownerId != %@", recipeId, newVote.ownerId!)
        let request = Vote.fetchRequest(predicate: recipePredicate)
        let votes = try! context.fetch(request)
        
        let isMatch = !votes.isEmpty && votes.allSatisfy({ $0.isLiked })
        return isMatch
    }
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
