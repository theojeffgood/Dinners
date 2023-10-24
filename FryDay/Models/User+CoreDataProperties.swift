//
//  User+CoreDataProperties.swift
//  FryDay
//
//  Created by Theo Goodman on 10/23/23.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var userType: Int32
    @NSManaged public var likedRecipes: NSSet?

}

// MARK: Generated accessors for likedRecipes
extension User {

    @objc(addLikedRecipesObject:)
    @NSManaged public func addToLikedRecipes(_ value: Recipe)

    @objc(removeLikedRecipesObject:)
    @NSManaged public func removeFromLikedRecipes(_ value: Recipe)

    @objc(addLikedRecipes:)
    @NSManaged public func addToLikedRecipes(_ values: NSSet)

    @objc(removeLikedRecipes:)
    @NSManaged public func removeFromLikedRecipes(_ values: NSSet)

}

extension User : Identifiable {

}
