//
//  User+CoreDataProperties.swift
//  FryDay
//
//  Created by Theo Goodman on 10/31/23.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var userType: Int32
    @NSManaged public var isShared: Bool
    @NSManaged public var likedRecipes: NSSet?
    @NSManaged public var dislikedRecipes: NSSet?

}

// MARK: Generated accessors for likedRecipes
extension User {

    @objc(addLikedRecipesObject:)
    @NSManaged public func likes(_ value: Recipe)

    @objc(removeLikedRecipesObject:)
    @NSManaged public func removeFromLikedRecipes(_ value: Recipe)

    @objc(addLikedRecipes:)
    @NSManaged public func likes(_ values: NSSet)

    @objc(removeLikedRecipes:)
    @NSManaged public func removeFromLikedRecipes(_ values: NSSet)

}

// MARK: Generated accessors for dislikedRecipes
extension User {

    @objc(addDislikedRecipesObject:)
    @NSManaged public func dislikes(_ value: Recipe)

    @objc(removeDislikedRecipesObject:)
    @NSManaged public func removeFromDislikedRecipes(_ value: Recipe)

    @objc(addDislikedRecipes:)
    @NSManaged public func dislikes(_ values: NSSet)

    @objc(removeDislikedRecipes:)
    @NSManaged public func removeFromDislikedRecipes(_ values: NSSet)

}

extension User : Identifiable {

}
