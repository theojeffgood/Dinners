//
//  ShareController.swift
//  FryDay
//
//  Created by Theo Goodman on 1/24/24.
//

import CloudKit
import OSLog
import CoreData

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
    private var  inAHousehold: Bool{ get{ UserDefaults.standard.bool(forKey: "inAHousehold")     } }
    private var ownsHousehold: Bool{ get{ UserDefaults.standard.bool(forKey: "isHouseholdOwner") } }
    
    init() {
        fetchActiveShare(in: stack.sharedStore)
    }
    
    func setActiveShare(_ share: CKShare? = nil){
        DispatchQueue.main.async {
            self.activeShare = share
        }
    }
    
    func fetchActiveShare(in coreDataStore: NSPersistentStore? = nil) {
        guard inAHousehold else { return }
        var dataStore = coreDataStore
        
        if dataStore == nil{
            dataStore = ownsHousehold ? stack.privateStore : stack.sharedStore }
        
        do {
            let shares = try stack.localContainer.fetchShares(in: dataStore)
            let existingShare = shares.filter({ $0.recordID.recordName == CKRecordNameZoneWideShare }).first // Can this falsely be nil
            self.activeShare = existingShare // this isn't async. doesn't need setActiveShare(in:)
            
        } catch { Logger.sharing.warning("Error fetching share from persistent store: \(error, privacy: .public)") }
    }
    
    func createShare() async throws {
        guard !inAHousehold || ownsHousehold else { return }
        fetchActiveShare(in: stack.privateStore)
        guard activeShare == nil else { return }
        let zoneName = "com.apple.coredata.cloudkit.zone"
        
        do {
            if let mainZone = try await getDefaultZone(titled: zoneName){
                           if try await getShare(from: mainZone){ return }
                        else{ try await shareZone(mainZone);      return }
            }
            
            else if let newZone = try await createZone(titled: zoneName){
                                  try await shareZone(newZone); return  }
            
        } catch{ Logger.sharing.warning("Failed to create share: \(error, privacy: .public)"); throw error }
    }
    
    func getDefaultZone(titled zoneName: String) async throws -> CKRecordZone?{ // should this be optional? 1 of 2
        do{
            let allZones = try await stack.ckContainer.privateCloudDatabase.allRecordZones()
            if let mainZone = allZones.filter({ $0.zoneID.zoneName == zoneName }).first{
                Logger.sharing.info("Default zone found. Trying to share.")
                return mainZone
                
            } else { Logger.sharing.warning("The defaultZone doesn't exist.") }
        } catch{ Logger.sharing.warning("The defaultZone doesn't exist."); throw error }
        return nil
    }
    
    func createZone(titled zoneName: String) async throws -> CKRecordZone?{ // should this be optional? 2 of 2
        do{
            let mainZone = CKRecordZone(zoneName: zoneName)
            let results = try await stack.ckContainer.privateCloudDatabase.modifyRecordZones(
                saving: [mainZone], deleting: [] )
            Logger.sharing.info("Created new defaultZone: \(results.saveResults)")
            return mainZone
            
        } catch{ Logger.sharing.warning("Failed to create new defaultZone: \(error, privacy: .public)"); throw error }
//        return nil
    }
    
    func shareZone(_ recipeZone: CKRecordZone) async throws{
        let share = CKShare(recordZoneID: recipeZone.zoneID)
//        share.publicPermission = .readOnly
        share.publicPermission = .none //TO DO: MAYBE make the share public? instead of private..
        
        do{
            let result = try await stack.ckContainer.privateCloudDatabase.save(share)
            setActiveShare((result as! CKShare))
            
        } catch{ Logger.sharing.warning("Failed to save share: \(error, privacy: .public)") }
    }
}

//MARK: -- SHARE Vote, Category, or Zone METHODS

extension ShareCoordinator{
    
    func getShare(from zone: CKRecordZone) async throws -> Bool{
        guard zone.capabilities.contains(.zoneWideSharing),
              let shareReference = zone.share else { return false }
        Logger.sharing.info("DefaultZone is shared. Fetching its CKShare record.")
        
        do {
            guard let share = try await stack.ckContainer.privateCloudDatabase.record(for: shareReference.recordID) as? CKShare else { return false }
            setActiveShare(share)
            return true
            
        } catch { Logger.sharing.warning("DefaultZone is shared. But couldn't get its CKShare: \(error, privacy: .public)"); throw error }
    }
    
    func shareIfNeeded(_ voteOrPurchase: NSManagedObject, completion: @escaping () -> Void) async {
        guard inAHousehold, !ownsHousehold else { return }
        
        if activeShare == nil{ fetchActiveShare(in: stack.sharedStore) }
        if activeShare == nil{ return }
        
        Task.detached(operation: {
            do{
                self.stack.localContainer.share([voteOrPurchase], to: self.activeShare) { objectIds, share, container, error in
                    if let error{ Logger.sharing.warning("Failed to share vote: \(error, privacy: .public)") }
                    
                    else{
                        switch voteOrPurchase {
                        case is Vote:
                            Logger.sharing.info("Successfully shareed vote: \((voteOrPurchase as! Vote).recipeId)")
                        case is Purchase:
                            Logger.sharing.info("Successfully shareed purchase: \((voteOrPurchase as! Purchase).categoryId)")
                        default:
                            fatalError("Expected Vote or Purchase. Unrecognized object type")
                        }
                    }
                    completion()
                }
            }
        })
    }
}



extension ShareCoordinator{
    func exitShare() async{
        if activeShare == nil{
            fetchActiveShare(in: stack.sharedStore)
        }
        
        guard let shareRecordId = activeShare?.recordID else { Logger.sharing.info("No share exists to leave."); return }
        do {
            try await stack.ckContainer.sharedCloudDatabase.deleteRecord(withID: shareRecordId)
            setActiveShare(nil)
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
