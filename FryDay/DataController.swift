//
//  DataController.swift
//  FryDay
//
//  Created by Theo Goodman on 2/16/23.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    
    let container = NSPersistentContainer(name: "MealSwipe")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error{
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
}
