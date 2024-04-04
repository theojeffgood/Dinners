//
//  User+CoreDataProperties.swift
//  FryDay
//
//  Created by Theo Goodman on 10/31/23.
//
//

//import Foundation
//import CoreData
//
//public class User: NSManagedObject {
//    
//}
//
////// a convenient extension to set up the fetch request
////extension User {
////  static var currentUserFetchRequest: NSFetchRequest<User> {
////      
////    let request: NSFetchRequest<User> = User.fetchRequest()
//////      request.predicate = NSPredicate(format: "id = %@", UserDefaults.standard.string(forKey: "userID")!)
////    request.predicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [
////        NSPredicate(format: "id = %@",
////                    UserDefaults.standard.string(forKey: "userID")!),
////        NSPredicate(format: "isShared == %d",
////                    UserDefaults.standard.bool(forKey: "inAHousehold")) ])
////      request.fetchLimit = 1
//////    request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
////      request.sortDescriptors = []
////
////    return request
////  }
////    
//////    static var allUsersFetchRequest: NSFetchRequest<User> {
//////        let request: NSFetchRequest<User> = User.fetchRequest()
//////      let request: NSFetchRequest<User> = User.fetchRequest(predicate: NSPredicate(format: "isShared == %d",
//////                                                                                   UserDefaults.standard.bool(forKey: "inAHousehold")))
////  //    request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
//////        request.sortDescriptors = []
//////
//////      return request
//////    }
////}
//
//
//
//extension User {
//
////    @nonobjc public class func fetchRequest(sort: [NSSortDescriptor] = [], predicate: NSPredicate? = nil) -> NSFetchRequest<User> {
////        let fetchRequest = NSFetchRequest<User>(entityName: String(describing: User.self))
////        fetchRequest.predicate = predicate        
////        fetchRequest.sortDescriptors = sort
////
//////        if UserDefaults.standard.bool(forKey: "inAHousehold") &&
//////           !UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
//////            fetchRequest.affectedStores = [DataController.shared.sharedPersistentStore]
//////        }
////        
////        return fetchRequest
////    }
//
//    @NSManaged public var id: String?
//    @NSManaged public var name: String?
//    @NSManaged public var userType: Int32
////    @NSManaged public var isShared: Bool
////    @NSManaged public var likedRecipes: NSSet?
////    @NSManaged public var dislikedRecipes: NSSet?
//
//}
//
////// MARK: Generated accessors for likedRecipes
////extension User {
////
////    @objc(addLikedRecipesObject:)
////    @NSManaged public func likes(_ value: Recipe)
////
////    @objc(removeLikedRecipesObject:)
////    @NSManaged public func removeFromLikedRecipes(_ value: Recipe)
////
////    @objc(addLikedRecipes:)
////    @NSManaged public func likes(_ values: NSSet)
////
////    @objc(removeLikedRecipes:)
////    @NSManaged public func removeFromLikedRecipes(_ values: NSSet)
////
////}
////
////// MARK: Generated accessors for dislikedRecipes
////extension User {
////
////    @objc(addDislikedRecipesObject:)
////    @NSManaged public func dislikes(_ value: Recipe)
////
////    @objc(removeDislikedRecipesObject:)
////    @NSManaged public func removeFromDislikedRecipes(_ value: Recipe)
////
////    @objc(addDislikedRecipes:)
////    @NSManaged public func dislikes(_ values: NSSet)
////
////    @objc(removeDislikedRecipes:)
////    @NSManaged public func removeFromDislikedRecipes(_ values: NSSet)
////
////}
//
//extension User : Identifiable {
//
//}
