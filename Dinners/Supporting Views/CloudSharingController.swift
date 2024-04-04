//
//  CloudSharingController.swift
//  FryDay
//
//  Created by Theo Goodman on 10/10/23.
//

import SwiftUI
import CloudKit
import OSLog

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer = DataController.shared.ckContainer
    
    func makeCoordinator() -> CloudSharingCoordinator {
        CloudSharingCoordinator()
    }
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        share[CKShare.SystemFieldKey.title] = "Great Recipes"
        
//        if let cover = UIImage(named: "PLACEHOLDER FOR ICON FROM JULIE"), let data = cover.pngData() {
//            share[CKShare.SystemFieldKey.thumbnailImageData] = data
//        }
        
        let controller = UICloudSharingController(share: share, container: container)
        controller.modalPresentationStyle = .formSheet
        controller.availablePermissions = [.allowReadWrite, .allowPrivate] //TO DO: TEST WHAT PUBLIC SHARE LOOKS LIKE
//        controller.availablePermissions = [.allowPublic] //TO DO: MAYBE make the share public? instead of private..
        controller.delegate = context.coordinator
        
        let asdf = controller.share!.publicPermission.rawValue.description
        Logger.sharing.info("Share's public permissions are: \(asdf, privacy: .public)")
        
//         Needed to avoid crash on iPad
//        if let popover = controller.popoverPresentationController {
//            popover.barButtonItem = barButtonItem
//          }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) { }
}

final class CloudSharingCoordinator: NSObject, UICloudSharingControllerDelegate {
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        "Great Recipes"
    }
    
//    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
// attempt #1
//        guard let cover = UIImage(named: "PLACEHOLDER FOR ICON FROM JULIE"), let data = cover.pngData() else { return nil }
//            share[CKShare.SystemFieldKey.thumbnailImageData] = data
//            return data
        
// attempt #2
//        guard let icon = NSDataAsset(name: "thumbnail") else { return nil }
//        return icon.data
//    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        Logger.sharing.info("cloudSharingController Failed to save share: \(error, privacy: .public).")
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        Logger.sharing.info("cloudSharingControllerDidSaveShare.")
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        Logger.sharing.info("cloudSharingControllerDidStopSharing.")
    }
}
