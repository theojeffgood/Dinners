//
//  CloudSharingController.swift
//  FryDay
//
//  Created by Theo Goodman on 10/10/23.
//

import SwiftUI
import CloudKit

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    
    func makeCoordinator() -> CloudSharingCoordinator {
        CloudSharingCoordinator()
    }
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
//        share[CKShare.SystemFieldKey.title] = recipe.title
        share[CKShare.SystemFieldKey.title] = "The Fryday CookBook."
        let controller = UICloudSharingController(share: share, container: container)
        controller.modalPresentationStyle = .formSheet
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
    }
}

final class CloudSharingCoordinator: NSObject, UICloudSharingControllerDelegate {
    let stack = DataController.shared
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        "The Fryday Cookbook."
    }
    
//    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
//        guard let icon = NSDataAsset(name: "thumbnail") else {
//            return nil
//        }
//        
//        
//        return icon.data
//    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("Failed to save share: \(error)")
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("Saved the share")
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
//        if !stack.isOwner(object: recipe) {
//            stack.delete(recipe)
//        }
    }
}

class ShareCoordinator: NSObject{
    let stack = DataController.shared
    
    var shareExists: Bool{
        get async throws{
            let allZones = try await stack.ckContainer.privateCloudDatabase.allRecordZones()
            guard let recipeZone = allZones.first(where: { $0.zoneID.zoneName == "com.apple.coredata.cloudkit.zone" }) else {
                fatalError("no recipe zone exists in cloudkit.")
            }
            
            //        let lookIntoThis = CKRecordNameZoneWideShare use this to re-do the check for existing share. also use a static zone to make creation of share easier
            
            if recipeZone.capabilities.contains(.zoneWideSharing),
               let shareList = try? stack.persistentContainer.fetchShares(in: stack.privatePersistentStore),
               let existingShare = shareList.first,
               existingShare.recordID.recordName == CKRecordNameZoneWideShare{
                return true
            }
            return false
        }
    }
    
    func createShare() async throws -> CKShare {
        let allZones = try await stack.ckContainer.privateCloudDatabase.allRecordZones()
        guard let recipeZone = allZones.first(where: { $0.zoneID.zoneName == "com.apple.coredata.cloudkit.zone" }) else {
            fatalError("no recipe zone exists in cloudkit.")
        }
        
//        let lookIntoThis = CKRecordNameZoneWideShare use this for the share check
        
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
    
    func getParticipants() async -> [CKShare.Participant]{
        let allZones = try? await stack.ckContainer.privateCloudDatabase.allRecordZones()
        guard let recipeZone = allZones?.first(where: { $0.zoneID.zoneName == "com.apple.coredata.cloudkit.zone" }) else {
            fatalError("no recipe zone exists in cloudkit.")
        }
        
        if recipeZone.capabilities.contains(.zoneWideSharing),
           let shareList = try? stack.persistentContainer.fetchShares(in: stack.privatePersistentStore),
           let existingShare = shareList.first{
            let participants = existingShare.participants
            return participants
        }
        return []
    }
}
