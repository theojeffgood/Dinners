//
//  ShareController.swift
//  FryDay
//
//  Created by Theo Goodman on 1/24/24.
//

import Foundation
import CloudKit

//class ShareCoordinator: NSObject, ObservableObject{
//    static let shared = DataController()

final class ShareCoordinator: ObservableObject {
    static let shared = ShareCoordinator()
    var existingShare: CKShare?
    
    func fetchShare() {
        guard UserDefaults.standard.bool(forKey: "inAHousehold") else { return }
        let stack = DataController.shared
        
        let persistentStore = UserDefaults.standard.bool(forKey: "isHouseholdOwner") ?
        stack.privatePersistentStore : stack.sharedPersistentStore
        
        guard let share = try? stack.persistentContainer.fetchShares(in: persistentStore)
            .first(where: { $0.recordID.recordName == CKRecordNameZoneWideShare}) else { return }
        self.existingShare = share
        
//        switch isInAHousehold {
//        case true:
//
//            switch isHouseholdOwner {
//            case true:
//                let shareList = try? stack.persistentContainer.fetchShares(in: stack.privatePersistentStore)
//                let share = shareList?.first(where: { $0.recordID.recordName == CKRecordNameZoneWideShare})
//                self.existingShare = share
//
//            case false:
//                let share = try? stack.persistentContainer.fetchShares(in: stack.sharedPersistentStore).first
//                self.existingShare = share
//            }
//
//        case false:
//            return
//        }
    }
    
    func createShare() async throws -> CKShare {
        let stack = DataController.shared
        
        let allZones = try await stack.ckContainer.privateCloudDatabase.allRecordZones()
        guard let recipeZone = allZones.first(where: { $0.zoneID.zoneName == "com.apple.coredata.cloudkit.zone" }) else {
            fatalError("no recipe zone exists in cloudkit.")
        }
                
        if recipeZone.capabilities.contains(.zoneWideSharing),
           let shareList = try? stack.persistentContainer.fetchShares(in: stack.privatePersistentStore),
           let existingShare = shareList.first,
              existingShare.recordID.recordName == CKRecordNameZoneWideShare{
            return existingShare
            
        } else{
            _ = try await stack.ckContainer.privateCloudDatabase.modifyRecordZones(
                saving: [CKRecordZone(zoneName: recipeZone.zoneID.zoneName)],
                deleting: [] )
            
            let share = CKShare(recordZoneID: recipeZone.zoneID)
            share.publicPermission = .readOnly
            let result = try await stack.ckContainer.privateCloudDatabase.save(share)
            return result as! CKShare
        }
    }
    
    func getParticipants(share existingShare: CKShare?) async -> [CKShare.Participant]{
        guard let existingShare else { return [] }
        let participants = existingShare.participants
        return participants
    }
    
    func shareVoteIfNeeded(_ vote: Vote){
        if UserDefaults.standard.bool(forKey: "inAHousehold"),
           !UserDefaults.standard.bool(forKey: "isHouseholdOwner"),
           let existingShare{
            
            let stack = DataController.shared
            stack.persistentContainer.share([vote], to: existingShare) { _, _, _, error in
                if let error{
                    print("attempted to save vote: \(vote)")
                    fatalError("### failed to share vote: \(error)") }
            }
        }
    }
}

extension CKShare.Participant: Identifiable{}
