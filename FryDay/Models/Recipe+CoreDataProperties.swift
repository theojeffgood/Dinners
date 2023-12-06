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

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<Recipe> {
//        return NSFetchRequest<Recipe>(entityName: "Recipe")
//    }

    @NSManaged public var cooktime: String?
    @NSManaged public var id: UUID?
    @NSManaged public var imageUrl: String?
    @NSManaged public var ingredients: [Int]?
//    @NSManaged public var categories: [Int]?
//    @NSManaged public var isLiked: Bool
    @NSManaged public var isLiked: Bool
    @NSManaged public var isShared: Bool
    @NSManaged public var recipeId: Int64
    @NSManaged public var recipeStatusId: Int16
    @NSManaged public var likesCount: Int32
    @NSManaged public var source: String?
    @NSManaged public var title: String?
    @NSManaged public var websiteUrl: String?
    @NSManaged public var user: NSSet?
    @NSManaged public var userDislikes: NSSet?

}

// MARK: Generated accessors for user
extension Recipe {

    @objc(addUserObject:)
    @NSManaged public func addToUser(_ value: User)

    @objc(removeUserObject:)
    @NSManaged public func removeFromUser(_ value: User)

    @objc(addUser:)
    @NSManaged public func addToUser(_ values: NSSet)

    @objc(removeUser:)
    @NSManaged public func removeFromUser(_ values: NSSet)

}

// MARK: Generated accessors for userDislikes
extension Recipe {

    @objc(addUserDislikesObject:)
    @NSManaged public func addToUserDislikes(_ value: User)

    @objc(removeUserDislikesObject:)
    @NSManaged public func removeFromUserDislikes(_ value: User)

    @objc(addUserDislikes:)
    @NSManaged public func addToUserDislikes(_ values: NSSet)

    @objc(removeUserDislikes:)
    @NSManaged public func removeFromUserDislikes(_ values: NSSet)

}

//extension Recipe : Identifiable {
//
//}
