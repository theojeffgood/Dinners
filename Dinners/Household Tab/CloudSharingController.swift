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
        share[CKShare.SystemFieldKey.title] = "Join my Dinners Crew"
        if let appIcon = UIImage(named: "AppIcon"), let data = appIcon.pngData() {
            share[CKShare.SystemFieldKey.thumbnailImageData] = data
        }
        
        let controller = UICloudSharingController(share: share, container: container)
        controller.modalPresentationStyle = .formSheet
        controller.availablePermissions = [.allowReadWrite, .allowPrivate] //TO DO: TEST WHAT PUBLIC SHARE LOOKS LIKE
//        controller.availablePermissions = [.allowPublic] //TO DO: MAYBE make the share public? instead of private..
        controller.delegate = context.coordinator
        
        let publicPermissions = controller.share!.publicPermission.rawValue.description
        Logger.sharing.info("Share's public permissions are: \(publicPermissions, privacy: .public)")
        
        //** Avoid crash on iPad **//
//        if let popover = controller.popoverPresentationController {
//            popover.barButtonItem = barButtonItem
//          }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) { }
}

final class CloudSharingCoordinator: NSObject, UICloudSharingControllerDelegate {
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        "Join my Dinners Crew"
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        guard let icon = UIImage(named: "AppIcon"), let thumbnail = icon.pngData() else { return nil }
        return thumbnail
    }
    
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
