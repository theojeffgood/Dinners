//
//  PurchaseManager.swift
//  Dinners
//
//  Created by Theo Goodman on 4/23/24.
//

import CloudKit
import CoreData
import OSLog

class PurchaseManager{
    let stack = DataController.shared
    
    func createPurchase(for categoryId: Int64, share: CKShare? = nil){
        
        stack.localContainer.performBackgroundTask { context in
            let purchase = Purchase(categoryId: categoryId, in: context)
            
            do{
                try context.save()
                if let share,
                   UserDefaults.standard.bool(forKey: "inAHousehold"),
                   !UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
                    
                    self.share(purchase, to: share)
                }
                
            } catch{ print("Error saving vote: \(error.localizedDescription)") }
        }
    }
    
    func share(_ vote: NSManagedObject, to share: CKShare) {
        
        do{
            self.stack.localContainer.share([vote], to: share) { objectIds, share, container, error in
                if let error{ Logger.sharing.warning("Failed to share purchase: \(error, privacy: .public)")}
                else{ Logger.sharing.info("Successfully shareed purchase: \((vote as! Purchase).categoryId)")}
            }
        }
    }
}
