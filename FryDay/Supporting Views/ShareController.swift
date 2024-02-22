//
//  ShareController.swift
//  FryDay
//
//  Created by Theo Goodman on 1/24/24.
//

import CloudKit
import OSLog
import CoreData

@MainActor
final class ShareCoordinator: ObservableObject {
    
    @Published var existingShare: CKShare?
    
    static let shared = ShareCoordinator()
    let stack = DataController.shared
    
    func fetchExistingShare(in localStore: NSPersistentStore? = nil) {
        guard UserDefaults.standard.bool(forKey: "inAHousehold") else { return }
        var persistentStore = localStore
        
        if persistentStore == nil{
            persistentStore = UserDefaults.standard.bool(forKey: "isHouseholdOwner") ?
            stack.privatePersistentStore : stack.sharedPersistentStore
        }
        
        do {
            let shares = try stack.persistentContainer.fetchShares(in: persistentStore)
            self.existingShare = shares.filter({ $0.recordID.recordName == CKRecordNameZoneWideShare }).first
            
        } catch { Logger.share.warning("Error fetching share from persistent store: \(error)") }
    }
    
    /* TO DO: Get rid of Throws? or throw error. */
    func getShare() async throws {
        fetchExistingShare(in: stack.privatePersistentStore)
        if existingShare != nil { return }
        
        let defaultZone = "com.apple.coredata.cloudkit.zone"
        do { /* Step 1: Existing zone. Share. */
            let allZones = try await stack.ckContainer.privateCloudDatabase.allRecordZones()
            if let defaultZone = allZones.filter({ $0.zoneID.zoneName == defaultZone }).first{
//                if let share = fetchShareFromZone(_ zone: defaultZone){ self.existingShare = share; return } - OR ->
//                if let share = defaultZone.share, defaultZone.capabilities.contains(.zoneWideSharing){ self.existingShare = share; return }
                await shareZone(defaultZone)
                return
                
            } else { Logger.share.warning("The defaultZone doesn't exist.") }
        } catch { Logger.share.warning("Failed to fetch CloudKit zones: \(error)") }

        do{ /* Step 2: New zone. Create & Share. */
            let newDefaultZone = CKRecordZone(zoneName: defaultZone)
            let results = try await stack.ckContainer.privateCloudDatabase.modifyRecordZones(
                saving: [newDefaultZone], deleting: [] )
            Logger.share.info("Created new defaultZone: \(results.saveResults)")
            await shareZone(newDefaultZone)
            return
            
        } catch{ Logger.share.warning("Failed to create new defaultZone: \(error)") }
    }
    
    func shareZone(_ recipeZone: CKRecordZone) async{
        let share = CKShare(recordZoneID: recipeZone.zoneID)
        share.publicPermission = .readOnly
//        share.publicPermission = .none //TO DO: uncomment this line. OR make the share public.
        
        do{
            let result = try await stack.ckContainer.privateCloudDatabase.save(share)
            self.existingShare = (result as! CKShare)
            
        } catch{ Logger.share.warning("Failed to save share: \(error)") }
    }
    
//    func fetchShareFromZone(_ zone: CKRecordZone,
//                            completion: @escaping (Result<CKShare, Error>) -> Void) {
//        let database = CKContainer.default().privateCloudDatabase
//        
//        // Use the 'CKRecordNameZoneWideShare' constant to create the record ID.
//        let recordID = CKRecord.ID(recordName: CKRecordNameZoneWideShare,
//                                   zoneID: zone.zoneID)
//        
//        // Fetch the share record from the specified record zone.
//        database.fetch(withRecordID: recordID) { share, error in
//            if let error = error {
//                // If the fetch fails, inform the caller.
//                completion(.failure(error))
//            } else if let share = share as? CKShare {
//                // Otherwise, pass the fetched share record to the
//                // completion handler.
//                completion(.success(share))
//            } else {
//                fatalError("Unable to fetch record with ID: \(recordID)")
//            }
//        }
//    }
}

extension ShareCoordinator{
    
    func shareVoteIfNeeded(_ vote: Vote) {
        guard UserDefaults.standard.bool(forKey: "inAHousehold"),
              !UserDefaults.standard.bool(forKey: "isHouseholdOwner"),
              let existingShare else { return }
        
        Task{
            do{
                try await stack.persistentContainer.share([vote], to: existingShare)
                
            } catch{ Logger.share.warning("Failed to share vote: \(error)") }
        }
    }
}







extension CKShare.Participant: Identifiable{ }

extension CKShare.ParticipantAcceptanceStatus{
    var description: String{
        switch self {
        case .accepted:
            return "Accepted"
        case .unknown:
            return "Unknown"
        case .removed:
            return "Removed"
        case .pending:
            return "Pending"
        }
    }
}

// MARK: -- Returns CKShare participant permission, methods and properties to share

//extension Household {
//    private func image(for role: CKShare.ParticipantRole) -> String {
//        switch role {
//        case .owner:
//            return "😎"
//        case .privateUser:
//            return "😎"
//        case .publicUser:
//            return "😎"
//        case .unknown:
//            return "🥳"
//        @unknown default:
//            fatalError("A new value added to CKShare.Participant.Role")
//        }
//    }
//    private func string(for permission: CKShare.ParticipantPermission) -> String {
//        switch permission {
//        case .unknown:
//            return "Unknown"
//        case .none:
//            return "None"
//        case .readOnly:
//            return "Read-Only"
//        case .readWrite:
//            return "Read-Write"
//        @unknown default:
//            fatalError("A new value added to CKShare.Participant.Permission")
//        }
//    }
//    
//    private func string(for role: CKShare.ParticipantRole) -> String {
//        switch role {
//        case .owner:
//            return "Owner"
//        case .privateUser:
//            return "Private User"
//        case .publicUser:
//            return "Public User"
//        case .unknown:
//            return "Unknown"
//        @unknown default:
//            fatalError("A new value added to CKShare.Participant.Role")
//        }
//    }
//    
//    private func string(for acceptanceStatus: CKShare.ParticipantAcceptanceStatus) -> String {
//        switch acceptanceStatus {
//        case .accepted:
//            return "Accepted"
//        case .removed:
//            return "Removed"
//        case .pending:
//            return "Invited"
//        case .unknown:
//            return "Unknown"
//        @unknown default:
//            fatalError("A new value added to CKShare.Participant.AcceptanceStatus")
//        }
//    }
//}
