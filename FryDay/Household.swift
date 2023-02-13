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
    @State private var users: [User] = []
    @State private var emailAddress: String = ""
    @State private var householdState: HouseholdState = .notLoggedIn
    enum HouseholdState {
        case loggedIn
        case notLoggedIn
        case addMember
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
                HStack(spacing: 5){
                    Image(systemName: "house.fill")
                    Text("Household")
                        .font(.system(size: 28, weight: .bold))
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
                    VStack(){
                        Text("Send invitation")
                            .font(.system(size: 22, weight: .medium))
                            .multilineTextAlignment(.center)
                        HStack{
                            Spacer()
                            Button(action: {
                                ShareHelper.shared.sendText()
//                                householdState = .loggedIn
//                                users.append(User(userType: .pending))
                            }) {
                                Image("imessage")
//                                    .resizable()
                            }
                            Spacer()
                            Button(action: {
//                                ShareHelper.shared.sendText()
//                                householdState = .loggedIn
//                                users.append(User(userType: .pending))
                            }) {
                                Image("whatsapp")
//                                    .resizable()
                            }
                            Spacer()
                            Button(action: {
                                ShareHelper.shared.sendEmail(subject: "Join me on MealSwipe",
                                                             body: "Create a meal plan with me on MealSwipe. Tap to join my account. \n\nhello://com.mealswipe",
                                                             to: "")
//                                householdState = .loggedIn
//                                users.append(User(userType: .pending))
                            }) {
                                Image("email")
//                                    .resizable()
                            }
                            Spacer()
                        }
                        .padding([.bottom])
                    }
                }
            }
            .padding()
            .padding(.bottom)
            .background(Color.white)
            .cornerRadius(20)
        }
        .ignoresSafeArea()
        
    }
}

struct Household_Previews: PreviewProvider {
    static var previews: some View {
        Household(dismissAction: {})
        //            .previewLayout(.sizeThatFits)
    }
}


struct User: Identifiable {
    var id = UUID()
    var userType: UserType = .pending
    
    enum UserType {
        case member
        case pending
        
        var text: String{
            switch self {
            case .member:
                return "You"
            case .pending:
                return "Pending"
            }
        }
        
        var image: String{
            switch self {
            case .member:
                return "😎"
            case .pending:
                return "🥳"
            }
        }
    }
}



class ShareHelper: NSObject {
    
    public static let shared = ShareHelper()
    private override init() {}
    
    static func getRootViewController() -> UIViewController? {
        UIApplication.shared.windows.first?.rootViewController
    }
}

//MARK: -- EMAIL

extension ShareHelper: MFMailComposeViewControllerDelegate{
    
    func sendEmail(subject: String, body: String, to: String){
        guard MFMailComposeViewController.canSendMail() else {
            print("No mail account found")
            // Todo: Add a way to show banner to user about no mail app found or configured
            // Utilities.showErrorBanner(title: "No mail account found", subtitle: "Please setup a mail account")
            return
        }
        
        let picker = MFMailComposeViewController()
        
        picker.setSubject(subject)
        picker.setMessageBody(body, isHTML: true)
        picker.setToRecipients([to])
        picker.mailComposeDelegate = self
        
        ShareHelper.getRootViewController()?.present(picker, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        ShareHelper.getRootViewController()?.dismiss(animated: true, completion: nil)
    }
}

//MARK: -- TEXT MESSAGE

extension ShareHelper: MFMessageComposeViewControllerDelegate{
    
    func sendText(){
        guard MFMessageComposeViewController.canSendText() else {
            print("No message account found")
            return
        }
        
        let controller = MFMessageComposeViewController()
        
        controller.body = "Create a meal plan with me on MealSwipe. Tap to join my account. \n\nhello://com.mealswipe"
        controller.messageComposeDelegate = self
        controller.recipients = []
        
        ShareHelper.getRootViewController()?.present(controller, animated: true, completion: nil)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
