//
//  ShareHelper.swift
//  FryDay
//
//  Created by Theo Goodman on 10/11/23.
//

//This was created to facilitate sharing prior to CloudKitSharing. 

import Foundation
import MessageUI

class ShareHelper: NSObject {

    public static let shared = ShareHelper()
    private var completion: (() -> Void)?

    let subject = "Join me on Dinners"
//    let body = "Create a meal plan with me! I made an account on MealSwipe. You can join it, free. \n\nhello://com.mealswipe/xR3u1mr"
    let body = "Join my household on Dinners App \n\n"
//    let recipient = ""

//    private override init() {}

    static func getRootViewController() -> UIViewController? {
//        UIApplication.shared.windows.first?.rootViewController
        UIApplication.shared.firstKeyWindow?.rootViewController
    }
    
    func share(_ link: URL, shareMethod: String){
        switch shareMethod{
        case "messages": sendText(link: link)
        case "whatsapp": sendWhatsApp(link: link)
        case "mail":     sendEmail(link: link)
        default:         fatalError("Didn't recognize inviteType")
        }
    }
}

//MARK: -- EMAIL

extension ShareHelper{
    
    func sendWhatsApp(link: URL, completion: (() -> Void)? = nil){
        let urlWhats = "whatsapp://send?text=\(self.body) + \(link)"
        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed){
            if let whatsappURL = URL(string: urlString) {
//                if UIApplication.shared.canOpenURL(whatsappURL){
                    UIApplication.shared.open(whatsappURL, options: [:], completionHandler: nil)
//                }
//                else {
//                    print("Install Whatsapp")
//                }
            }
        }
    }
}

extension ShareHelper: MFMailComposeViewControllerDelegate{

    func sendEmail(link: URL, completion: (() -> Void)? = nil){
        guard MFMailComposeViewController.canSendMail() else {
            print("No mail account found")
            // Todo: Add a way to show banner to user about no mail app found or configured
            // Utilities.showErrorBanner(title: "No mail account found", subtitle: "Please setup a mail account")
            return
        }

        self.completion = completion
        let picker = MFMailComposeViewController()

        picker.setSubject(self.subject)
        picker.setMessageBody(self.body + "\n" + "\(link)", isHTML: true)
        picker.setToRecipients([])
        picker.mailComposeDelegate = self

        ShareHelper.getRootViewController()?.present(picker,
                                                     animated: true,
                                                     completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
//        ShareHelper.getRootViewController()?.dismiss(animated: true, completion: nil)
        controller.dismiss(animated: true, completion: nil)
        if result == .sent{
            completion?()
            completion = nil
        }
    }
}

//MARK: -- TEXT MESSAGE

extension ShareHelper: MFMessageComposeViewControllerDelegate{

    func sendText(link: URL, completion: (() -> Void)? = nil){
        guard MFMessageComposeViewController.canSendText() else {
            print("No message account found")
            return
        }

        self.completion = completion
        let controller = MFMessageComposeViewController()

        controller.body = self.body + "\(link)"
        controller.messageComposeDelegate = self
        controller.recipients = []

        ShareHelper.getRootViewController()?.present(controller,
                                                     animated: true,
                                                     completion: nil)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
        if result == .sent{
            completion?()
            completion = nil
        }
    }
}

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        // 1
        let activeScene = windowScenes
            .filter { $0.activationState == .foregroundActive }
        // 2
        let firstActiveScene = activeScene.first
        let keyWindow = firstActiveScene?.keyWindow
        
        return keyWindow
    }
}
