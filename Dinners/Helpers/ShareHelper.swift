//
//  ShareHelper.swift
//  FryDay
//
//  Created by Theo Goodman on 10/11/23.
//

//This was created to facilitate sharing prior to CloudKitSharing. 

//import Foundation
//import MessageUI
//
//class ShareHelper: NSObject {
//
//    public static let shared = ShareHelper()
//    private var completion: (() -> Void)?
//
//    let subject = "Join me on MealSwipe"
//    let body = "Create a meal plan with me! I made an account on MealSwipe. You can join it, free. \n\nhello://com.mealswipe/xR3u1mr"
//    let recipient = ""
//
////    private override init() {}
//
//    static func getRootViewController() -> UIViewController? {
//        UIApplication.shared.windows.first?.rootViewController
//    }
//}
//
////MARK: -- EMAIL
//
//extension ShareHelper: MFMailComposeViewControllerDelegate{
//
//    func sendEmail(completion: (() -> Void)? = nil){
//        guard MFMailComposeViewController.canSendMail() else {
//            print("No mail account found")
//            // Todo: Add a way to show banner to user about no mail app found or configured
//            // Utilities.showErrorBanner(title: "No mail account found", subtitle: "Please setup a mail account")
//            return
//        }
//
//        self.completion = completion
//        let picker = MFMailComposeViewController()
//
//        picker.setSubject(self.subject)
//        picker.setMessageBody(self.body, isHTML: true)
//        picker.setToRecipients([self.recipient])
//        picker.mailComposeDelegate = self
//
//        ShareHelper.getRootViewController()?.present(picker,
//                                                     animated: true,
//                                                     completion: nil)
//    }
//
//    func mailComposeController(_ controller: MFMailComposeViewController,
//                               didFinishWith result: MFMailComposeResult,
//                               error: Error?) {
////        ShareHelper.getRootViewController()?.dismiss(animated: true, completion: nil)
//        controller.dismiss(animated: true, completion: nil)
//        if result == .sent{
//            completion?()
//            completion = nil
//        }
//    }
//}
//
////MARK: -- TEXT MESSAGE
//
//extension ShareHelper: MFMessageComposeViewControllerDelegate{
//
//    func sendText(completion: (() -> Void)? = nil){
//        guard MFMessageComposeViewController.canSendText() else {
//            print("No message account found")
//            return
//        }
//
//        self.completion = completion
//        let controller = MFMessageComposeViewController()
//
//        controller.body = self.body
//        controller.messageComposeDelegate = self
//        controller.recipients = []
//
//        ShareHelper.getRootViewController()?.present(controller,
//                                                     animated: true,
//                                                     completion: nil)
//    }
//
//    func messageComposeViewController(_ controller: MFMessageComposeViewController,
//                                      didFinishWith result: MessageComposeResult) {
//        controller.dismiss(animated: true, completion: nil)
//        if result == .sent{
//            completion?()
//            completion = nil
//        }
//    }
//}
