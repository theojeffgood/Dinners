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
    
    @Published var activeShare: CKShare?{
        didSet{
            let householdMembers = activeShare?.participants.filter({ $0.acceptanceStatus == .accepted })
            guard let householdCount = householdMembers?.count else { return }
            UserDefaults.standard.set(householdCount, forKey: "householdCount")
        }
    }
    static let shared = ShareCoordinator()
    let stack = DataController.shared
    
    init() {
        fetchActiveShare(in: stack.sharedPersistentStore)
    }
    
    func fetchActiveShare(in localStore: NSPersistentStore? = nil) {
        guard UserDefaults.standard.bool(forKey: "inAHousehold") else { return }
        var persistentStore = localStore
        
        if persistentStore == nil{
            persistentStore = UserDefaults.standard.bool(forKey: "isHouseholdOwner") ?
            stack.privatePersistentStore : stack.sharedPersistentStore
        }
        
        do {
            let shares = try stack.persistentContainer.fetchShares(in: persistentStore)
            let activeShare = shares.filter({ $0.recordID.recordName == CKRecordNameZoneWideShare }).first
            self.activeShare = activeShare
            
        } catch { Logger.sharing.warning("Error fetching share from persistent store: \(error, privacy: .public)") }
    }
    
    func getShare() async throws {
        guard !UserDefaults.standard.bool(forKey: "inAHousehold") || UserDefaults.standard.bool(forKey: "isHouseholdOwner") else { return }
        fetchActiveShare(in: stack.privatePersistentStore)
        if activeShare != nil { return }
        
        let zoneName = "com.apple.coredata.cloudkit.zone"
        do { /* Step 1: Existing zone. Share. */
            let allZones = try await stack.ckContainer.privateCloudDatabase.allRecordZones()
            if let mainZone = allZones.filter({ $0.zoneID.zoneName == zoneName }).first{
                if await getShare(from: mainZone){ return }
                    
                Logger.sharing.info("Default zone found. Not yet shared. Attempting to sharing it.")
                await shareZone(mainZone)
                return
                
            } else { Logger.sharing.warning("The defaultZone doesn't exist.") }
        } catch { Logger.sharing.warning("Failed to fetch CloudKit zones: \(error, privacy: .public)"); throw error }

        do{ /* Step 2: New zone. Create & Share. */
            let mainZone = CKRecordZone(zoneName: zoneName)
            let results = try await stack.ckContainer.privateCloudDatabase.modifyRecordZones(
                saving: [mainZone], deleting: [] )
            Logger.sharing.info("Created new defaultZone: \(results.saveResults)")
            await shareZone(mainZone)
            return
            
        } catch{ Logger.sharing.warning("Failed to create new defaultZone: \(error, privacy: .public)"); throw error }
    }
    
    func getShare(from zone: CKRecordZone) async -> Bool{
        guard zone.capabilities.contains(.zoneWideSharing),
              let shareReference = zone.share else { return false }
        Logger.sharing.info("DefaultZone is shared. Fetching its CKShare record.")
        
        do {
            let share = try await stack.ckContainer.privateCloudDatabase.record(for: shareReference.recordID) as? CKShare
            self.activeShare = share
            return true
            
        } catch {
            Logger.sharing.warning("defaultZone is shared. Failed to get its CKShare: \(error, privacy: .public)")
            return false
        }
    }
}

//MARK: -- SHARE Vote, Category, or Zone METHODS

extension ShareCoordinator{
    
    func shareZone(_ recipeZone: CKRecordZone) async{
        let share = CKShare(recordZoneID: recipeZone.zoneID)
//        share.publicPermission = .readOnly
        share.publicPermission = .none //TO DO: MAYBE make the share public? instead of private..
        
        do{
            let result = try await stack.ckContainer.privateCloudDatabase.save(share)
            self.activeShare = (result as! CKShare)
            
        } catch{ Logger.sharing.warning("Failed to save share: \(error, privacy: .public)") }
    }
    
    func shareIfNeeded(_ voteOrPurchase: NSManagedObject) async {
        guard UserDefaults.standard.bool(forKey: "inAHousehold"),
              !UserDefaults.standard.bool(forKey: "isHouseholdOwner") else { return }
        
        if activeShare == nil{ fetchActiveShare(in: stack.sharedPersistentStore) }
        if activeShare == nil{ return }
            
        Task{
            do{
                try await stack.persistentContainer.share([voteOrPurchase], to: activeShare)
            } catch{ Logger.sharing.warning("Failed to share vote: \(error, privacy: .public)") }
        }
    }
    
    //ALTERNATIVE METHOD FOR GETSHARE. 
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
    func leaveShare() async{
        if activeShare == nil{
            fetchActiveShare(in: stack.sharedPersistentStore)
        }
        
        guard let shareRecordId = activeShare?.recordID else { Logger.sharing.info("No share exists to leave."); return }
        do {
            try await stack.ckContainer.sharedCloudDatabase.deleteRecord(withID: shareRecordId)
            activeShare = nil
            UserDefaults.standard.set(false, forKey: "inAHousehold")
            Logger.sharing.info("Removed self from share.")
        } catch {
            Logger.sharing.warning("Failed to delete share: \(error, privacy: .public)")
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
