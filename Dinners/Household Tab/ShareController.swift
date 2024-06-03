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
    
    static let shared = ShareCoordinator()
    
    let stack = DataController.shared
    let defaultZoneName = "com.apple.coredata.cloudkit.zone"
    
    @Published var activeShare: CKShare?{
        didSet{
//            let householdMembers = activeShare?.participants.filter({ $0.acceptanceStatus == .accepted })
            let householdMembers = activeShare?.participants
            guard let householdCount = householdMembers?.count else { return }
            UserDefaults.standard.set(householdCount, forKey: "householdCount")
        }
    }
    
    private var ownsHousehold: Bool{ get{ UserDefaults.standard.bool(forKey: "isHouseholdOwner") } }
    private var  inAHousehold: Bool{ get{ UserDefaults.standard.bool(forKey: "inAHousehold")     } }
    
    init() {
//        fetchActiveShare(in: stack.sharedStore)
        fetchActiveShare()
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
            self.activeShare = existingShare // no async. so don't use setActiveShare()
            
        } catch { Logger.sharing.warning("Couldn't get share from local store: \(error, privacy: .public)") }
    }
    
    func createShare() async throws {
        guard !inAHousehold || ownsHousehold else { return }
        fetchActiveShare(in: stack.privateStore)
        guard activeShare == nil else { return }
        
        do {
            if let mainZone = try await getDefaultZone(){
                           if try await getShare(from: mainZone){ return }
                        else{ try await shareZone(mainZone);      return } }
            
            else if let newZone = try await createZone(){
                                  try await shareZone(newZone); return }
            
        } catch{ Logger.sharing.warning("Failed to create share: \(error, privacy: .public)"); throw error }
    }
}

//MARK: -- ZONE Methods

extension ShareCoordinator{
    
    func getDefaultZone() async throws -> CKRecordZone?{
        do{
            let allZones = try await stack.ckContainer.privateCloudDatabase.allRecordZones()
            guard let mainZone = allZones.filter({ $0.zoneID.zoneName == defaultZoneName }).first else { return nil }
            Logger.sharing.info("DefaultZone found. Trying to share.")
            return mainZone
                
        } catch{ Logger.sharing.warning("DefaultZone doesn't exist."); throw error }
    }
    
    func createZone() async throws -> CKRecordZone?{
        do{
            let mainZone = CKRecordZone(zoneName: defaultZoneName)
            let results = try await stack.ckContainer.privateCloudDatabase.modifyRecordZones(
                saving: [mainZone], deleting: [] )
            Logger.sharing.info("Created new defaultZone: \(results.saveResults)")
            return mainZone
            
        } catch{ Logger.sharing.warning("New zone creation failure: \(error, privacy: .public)"); throw error }
    }
    
    func shareZone(_ recipeZone: CKRecordZone) async throws{
        let share = CKShare(recordZoneID: recipeZone.zoneID)
//        share.publicPermission = .readOnly
        share.publicPermission = .none //TO DO: MAYBE make the share public? instead of private..
        
        do{
            let result = try await stack.ckContainer.privateCloudDatabase.save(share)
            guard let activeShare = result as? CKShare else { return }
            setActiveShare(activeShare)
            
        } catch{ Logger.sharing.warning("Failed to save share: \(error, privacy: .public)"); throw error }
    }
}

//MARK: -- SHARE Methods

extension ShareCoordinator{
    
    func getShare(from zone: CKRecordZone) async throws -> Bool{
        guard zone.capabilities.contains(.zoneWideSharing),
              let shareRef = zone.share else { return false }
        Logger.sharing.info("ZoneShare is active. Fetching the CKShare.")
        
        do {
            guard let share = try await stack.ckContainer.privateCloudDatabase.record(for: shareRef.recordID) as? CKShare else { return false }
            setActiveShare(share)
            return true
            
        } catch { Logger.sharing.warning("Zone is shared. Failed to get its CKShare: \(error, privacy: .public)"); throw error }
    }

    func exitShare() async{
        if activeShare == nil{
            fetchActiveShare(in: stack.sharedStore)
        }
        
        guard let shareRecordId = activeShare?.recordID else { Logger.sharing.info("No share found."); return }
        do {
            try await stack.ckContainer.sharedCloudDatabase.deleteRecord(withID: shareRecordId)
            UserDefaults.standard.set(false, forKey: "inAHousehold")
            Logger.sharing.info("Removed self from share.")
            setActiveShare(nil)
            
        } catch { Logger.sharing.warning("Failed to delete share: \(error, privacy: .public)") }
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
