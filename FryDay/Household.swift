//
//  Household.swift
//  FryDay
//
//  Created by Theo Goodman on 1/22/23.
//

import SwiftUI
import Combine

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
    
    //keyboard avoidance: https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/
    @State private var keyboardHeight: CGFloat = 0
    
    
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
                    VStack(alignment: .leading){
                        Text("Add a member")
                            .frame(alignment: .leading)
                            .font(.system(size: 18, weight: .medium))
                        
                        TextField("Email Address",
                                  text: $emailAddress,
                                  prompt: Text("Enter an email"))
                        .submitLabel(.send)
                        .onSubmit {
                            householdState = .loggedIn
                            users.append(User(userType: .pending))
                            emailAddress = ""
                        }
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                        .padding([.bottom])
                        .padding(.bottom, keyboardHeight)
                        .onReceive(Publishers.keyboardHeight) { self.keyboardHeight = $0 }
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

extension Publishers {
    // 1.
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        // 2.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        // 3.
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
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
