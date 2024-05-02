//
//  VoteManager.swift
//  Dinners
//
//  Created by Theo Goodman on 4/23/24.
//

//import Foundation
import OSLog
import CloudKit
import CoreData

class VoteManager{
    
    let stack = DataController.shared
    
    func createVote(for recipeId: Int64, like: Bool, share: CKShare? = nil){
        
        stack.localContainer.performBackgroundTask { context in
            let vote = Vote(for: recipeId, like: like, in: context)
            
            do{
                try context.save()
                if let share,
                   UserDefaults.standard.bool(forKey: "inAHousehold"),
                   !UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
                    
                    self.share(vote, to: share)
                }
                
            } catch{ print("Error saving vote: \(error.localizedDescription)") }
        }
    }
    
    func share(_ vote: NSManagedObject, to share: CKShare) {

        do{
            self.stack.localContainer.share([vote], to: share) { objectIds, share, container, error in
                if let error{ Logger.sharing.warning("Failed to share vote: \(error, privacy: .public)"  )}
                else{         Logger.sharing.info("Successfully shared vote: \((vote as! Vote).recipeId)")}
            }
        }
    }
}

