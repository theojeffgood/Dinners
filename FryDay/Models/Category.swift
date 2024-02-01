//
//  Category + CoreData.swift
//  FryDay
//
//  Created by Theo Goodman on 1/30/24.
//

import Foundation
import CoreData
import StoreKit
//import CloudKit
//import SwiftUI

public class Category: NSManagedObject, Codable {
    @NSManaged public var id: Int64
    @NSManaged public var title: String
    @NSManaged public var group: String
    @NSManaged public var appStoreProductId: String
    var appStoreProduct: Product?
    
    convenience init(title: String,
                     group: String,
                     appStoreProductId: String,
                     id: Int64,
                     in context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.id = id
        self.title = title
        self.group = group
        self.appStoreProductId = appStoreProductId
    }
    
    private enum CodingKeys: String, CodingKey {
       case id = "id",
            title = "title",
            group = "group",
            appStoreProductId = "appStoreProductId"
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
              throw DecoderConfigurationError.missingManagedObjectContext
            }
        
        self.init(context: context)
        
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else { fatalError() }
        id = try! container.decode(Int64.self, forKey: .id)
        title = try! container.decode(String.self, forKey: .title)
        group = try! container.decode(String.self, forKey: .group)
        appStoreProductId = try! container.decode(String.self, forKey: .appStoreProductId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try! container.encode(id.self, forKey: .id)
        try! container.encode(title.self, forKey: .title)
        try! container.encode(group.self, forKey: .group)
        try! container.encode(appStoreProductId.self, forKey: .appStoreProductId)
      }
}

extension Category{
    
    @nonobjc public class func fetchRequest(sort: [NSSortDescriptor] = [],
                                            predicate: NSPredicate? = nil) -> NSFetchRequest<Category> {
        let fetchRequest = NSFetchRequest<Category>(entityName: String(describing: Category.self))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sort
        return fetchRequest
    }
    
    static func allCategories(in context: NSManagedObjectContext) -> [Category]{
        let request = fetchRequest()
        let categories = try! context.fetch(request)
        return categories
    }
}

extension Category: Identifiable{ }
