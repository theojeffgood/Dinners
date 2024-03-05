//
//  Vote.swift
//  FryDay
//
//  Created by Theo Goodman on 1/15/24.
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

public class Vote: NSManagedObject {
    @NSManaged public var date: Date?
    @NSManaged public var isLiked: Bool
    @NSManaged public var ownerId: String?
    @NSManaged public var recipeId: Int64
    
    var isCurrentUser: Bool{
        return ownerId == UserDefaults.standard.string(forKey: "userID")!
    }
    
    convenience init(forRecipeId recipeId: Int64,
                     like: Bool,
                     in context: NSManagedObjectContext) {
        self.init(context: context)
        
        let userId: String = UserDefaults.standard.string(forKey: "userID")!
//        let vote = Vote(context: context)
        self.isLiked = like
        self.date = Date.now
        self.ownerId = userId
        self.recipeId = recipeId
        
        assignToCorrectStore()
    }
}

extension Vote{
    
    @nonobjc public class func fetchRequest(sort: [NSSortDescriptor] = [], 
                                            predicate: NSPredicate? = nil) -> NSFetchRequest<Vote> {
        let fetchRequest = NSFetchRequest<Vote>(entityName: String(describing: Vote.self))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sort
        return fetchRequest
    }
    
    static var allVotes: NSFetchRequest<Vote>{
        let request: NSFetchRequest<Vote> = Vote.fetchRequest(sort: [])
        return request
    }
}
