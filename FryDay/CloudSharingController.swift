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
    let recipe: Recipe
    
    func makeCoordinator() -> CloudSharingCoordinator {
        CloudSharingCoordinator(recipe: recipe)
    }
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        share[CKShare.SystemFieldKey.title] = recipe.title
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
    let recipe: Recipe
    init(recipe: Recipe) {
        self.recipe = recipe
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        recipe.title
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("Failed to save share: \(error)")
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("Saved the share")
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        if !stack.isOwner(object: recipe) {
            stack.delete(recipe)
        }
    }
}
