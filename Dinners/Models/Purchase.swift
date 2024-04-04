//
//  Purchase.swift
//  FryDay
//
//  Created by Theo Goodman on 3/1/24.
//

import Foundation
import CoreData
import StoreKit

public class Purchase: NSManagedObject, Codable {
    @NSManaged public var id: UUID
    @NSManaged public var categoryId: Int64
    
    private enum CodingKeys: String, CodingKey {
       case id = "id",
            categoryId = "categoryId"
    }
    
    convenience init(categoryId: Int64,
                     in context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.categoryId = categoryId
        self.id = UUID()
        
        assignToCorrectStore()
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
              throw DecoderConfigurationError.missingManagedObjectContext
            }
        
        self.init(context: context)
        
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else { fatalError() }
        id = UUID()
        categoryId = try! container.decode(Int64.self, forKey: .categoryId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try! container.encode(id.self, forKey: .id)
        try! container.encode(categoryId.self, forKey: .categoryId)
      }
}

extension Purchase{
    
    @nonobjc public class func fetchRequest(sort: [NSSortDescriptor] = [],
                                            predicate: NSPredicate? = nil) -> NSFetchRequest<Purchase> {
        let fetchRequest = NSFetchRequest<Purchase>(entityName: String(describing: Purchase.self))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sort
        
//        if UserDefaults.standard.bool(forKey: "inAHousehold") &&
//           !UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
//            fetchRequest.affectedStores = [DataController.shared.sharedPersistentStore]
//        }
        
        return fetchRequest
    }
    
    static func allPurchases(in context: NSManagedObjectContext) -> [Purchase]{
        let request = fetchRequest()
        let purchases = try! context.fetch(request)
        return purchases
    }
}

extension Purchase: Identifiable{ }
