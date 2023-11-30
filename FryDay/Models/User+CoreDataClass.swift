//
//  User+CoreDataClass.swift
//  FryDay
//
//  Created by Theo Goodman on 10/23/23.
//
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

public class User: NSManagedObject {
    
}

// a convenient extension to set up the fetch request
extension User {
  static var dueSoonFetchRequest: NSFetchRequest<User> {
    let request: NSFetchRequest<User> = User.fetchRequest()
//    request.predicate = NSPredicate(format: "dueDate < %@", Date.nextWeek() as CVarArg)
//    request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
      request.sortDescriptors = []

    return request
  }
}

//class UserManager: NSObject, ObservableObject {
//    
//    @Published var currentUser: User?
//    @Published var householdUsers: [User] = []
//    private let usersController: NSFetchedResultsController<User>
//    
//    init(managedObjectContext: NSManagedObjectContext) {
//        usersController = NSFetchedResultsController(fetchRequest: User.dueSoonFetchRequest,
//                                                     managedObjectContext: managedObjectContext,
//                                                     sectionNameKeyPath: nil, cacheName: nil)
//        
//        super.init()
//        
//        usersController.delegate = self
//        
//        do {
//            try usersController.performFetch()
//            householdUsers = usersController.fetchedObjects ?? []
//        } catch {
//            print("failed to fetch items!")
//        }
//    }
//}
//
//extension UserManager: NSFetchedResultsControllerDelegate {
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        guard let users = controller.fetchedObjects as? [User]
//        else { return }
//        
//        householdUsers = users
//    }
//}
//
