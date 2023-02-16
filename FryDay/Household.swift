//
//  Household.swift
//  FryDay
//
//  Created by Theo Goodman on 1/22/23.
//

import SwiftUI
import Combine
import MessageUI

struct Household: View {
    
    @State var users: [User] = []
    @State private var emailAddress: String = ""
    @State private var householdState: HouseholdState = .notLoggedIn
    enum HouseholdState {
        case loggedIn
        case notLoggedIn
        case addMember
        case inviteSent
    }
    var dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: -15){
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .onTapGesture {
                    dismissAction()
                }
            VStack(spacing: 30){
                HStack(spacing: 7){
                    Image(systemName: "house.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                    Text("Household")
                        .font(.system(size: 30, weight: .bold))
                    Spacer()
                }
                
                switch householdState{
                    
//MARK: -- // NOT LOGGED IN //
                case .notLoggedIn:
                    Text("Please sign in to\n create a household.")
                        .font(.system(size: 20))
                        .multilineTextAlignment(.center)
                    Button("  Sign in with Apple            ") {
                        withAnimation {
                            users.append(User(userType: .member))
                            householdState = .loggedIn
                        }
                    }
                    .font(.system(size: 20))
                    .padding()
                    .background(Color.black)
                    .cornerRadius(30)
                    .foregroundColor(.white)
                    
//MARK: -- // LOGGED IN //
                case .loggedIn:
                    HStack(spacing: 10){
                        ForEach(users) { user in
                            VStack(spacing: 5){
                                ZStack{
                                    Circle()
                                        .padding([.leading, .trailing])
                                    Text(user.userType.image)
                                        .font(.system(size: 40))
                                    Button(action: {
                                        withAnimation {
                                            users.removeLast()
                                            if users.isEmpty{
                                                householdState = .notLoggedIn
                                            }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .resizable()
                                            .foregroundColor(.red)
                                    }
                                    .offset(x: 30, y: -30)
                                    .frame(width: 25, height: 25)
                                }
                                Text(user.userType.text)
                            }
                        }
                        
                        if users.count < 3{
                            VStack(spacing: 5){
                                Button(action: {
                                    withAnimation {
                                        householdState = .addMember
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 75, height: 75)
                                        .foregroundColor(.gray)
                                }
                                Text("Add a member")
                            }
                        }
                        
                        Spacer()
                    }.frame(height: 100)
                    
//MARK: -- // SEND AN INVITATION //
                case .addMember:
                    VStack(spacing: 15){
                        Text("Send invitation")
                            .font(.system(size: 22, weight: .medium))
                            .multilineTextAlignment(.center)
                        HStack(spacing: 50){
                            VStack{
                                Button(action: {
                                    ShareHelper.shared.sendText(){
                                        handleInviteSent()
                                    }
                                }) {
                                    Image("imessage")
                                }
                                Text("iMessage")
                            }
                            VStack{
                                Button(action: {
//                                    ShareHelper.shared.sendWhatsApp()
                                    handleInviteSent()
                                }) {
                                    Image("whatsapp")
                                }
                                Text("WhatsApp")
                            }
                            VStack{
                                Button(action: {
                                    ShareHelper.shared.sendEmail(){
                                        handleInviteSent()
                                    }
                                }) {
                                    Image("email")
                                }
                                Text("Email")
                            }
                        }
                        .padding([.bottom])
                    }
                    
                    
//MARK: -- // INVITE SENT //
                case .inviteSent:
                    Text("Invitation sent! 🎉")
                        .font(.system(size: 30, weight: .medium))
                        .multilineTextAlignment(.center)
                        .padding(50)
                }
            }
            .padding()
            .padding(.bottom)
            .background(Color.white)
            .cornerRadius(20)
        }
        .ignoresSafeArea()
        
    }
    func handleInviteSent(){
        withAnimation {
            householdState = .inviteSent
        }
        users.append(User(userType: .pending))
    }
}

struct Household_Previews: PreviewProvider {
    static var previews: some View {
        Household(users: [],
                  dismissAction: {})
    }
}




class ShareHelper: NSObject {
    
    public static let shared = ShareHelper()
    private var completion: (() -> Void)?
    
    let subject = "Join me on MealSwipe"
    let body = "Create a meal plan with me! I made an account on MealSwipe. You can join it, free. \n\nhello://com.mealswipe/xR3u1mr"
    let recipient = ""
    
//    private override init() {}
    
    static func getRootViewController() -> UIViewController? {
        UIApplication.shared.windows.first?.rootViewController
    }
}

//MARK: -- EMAIL

extension ShareHelper: MFMailComposeViewControllerDelegate{
    
    func sendEmail(completion: (() -> Void)? = nil){
        guard MFMailComposeViewController.canSendMail() else {
            print("No mail account found")
            // Todo: Add a way to show banner to user about no mail app found or configured
            // Utilities.showErrorBanner(title: "No mail account found", subtitle: "Please setup a mail account")
            return
        }
        
        self.completion = completion
        let picker = MFMailComposeViewController()
        
        picker.setSubject(self.subject)
        picker.setMessageBody(self.body, isHTML: true)
        picker.setToRecipients([self.recipient])
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
    
    func sendText(completion: (() -> Void)? = nil){
        guard MFMessageComposeViewController.canSendText() else {
            print("No message account found")
            return
        }
        
        self.completion = completion
        let controller = MFMessageComposeViewController()
        
        controller.body = self.body
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
