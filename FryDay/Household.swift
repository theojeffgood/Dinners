//
//  Household.swift
//  FryDay
//
//  Created by Theo Goodman on 1/22/23.
//

import SwiftUI
import Combine

struct Household: View {
    @State private var emailAddress: String = ""
    
//    @State private var loggedIn: Bool = false
    @State private var userType: UserType = .notLoggedIn
    enum UserType {
        case loggedIn
        case notLoggedIn
        case addMember
    }
    var dismissAction: () -> Void
    
    //keyboard avoidance: https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/
    @State private var keyboardHeight: CGFloat = 0

    
    var body: some View {
        VStack(spacing: 10){
            Spacer()
            ZStack{
                VStack(spacing: 30){
                    HStack(spacing: 5){
                        Image(systemName: "house.fill")
                        Text("Household")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                    }
                    
                    switch userType{
                    case .loggedIn:
                        HStack(spacing: 10){
                            VStack(spacing: 5){
                                ZStack{
                                    Circle()
                                        .padding([.leading, .trailing])
                                    Text("😎")
                                        .font(.system(size: 40))
                                }
                                Text("You")
                            }
                            VStack(spacing: 5){
                                    Button(action: {
                                        withAnimation {
                                            userType = .addMember
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .resizable()
                                            .frame(width: 75, height: 75)
                                            .foregroundColor(.black)
                                    }
                                Text("Add a member")
                            }
                            Spacer()
                            Spacer()
                        }.frame(height: 100)
                        
                    case .notLoggedIn:
                        Text("Please sign in to\n create a household.")
                            .font(.system(size: 20))
                            .multilineTextAlignment(.center)
                        Button("  Sign in with Apple            ") {
                            withAnimation {
                                userType = .loggedIn
                            }
                        }
                        .font(.system(size: 20))
                        .padding()
                        .background(Color.black)
                        .cornerRadius(30)
                        .foregroundColor(.white)
                        
                    case .addMember:
                        VStack(alignment: .leading){
                            Text("Add a member")
                                .frame(alignment: .leading)
                                .font(.system(size: 18, weight: .medium))
                            
                            TextField("Email Address",
                                      text: $emailAddress,
                                      prompt: Text("Enter the email"))
                                .padding()
    //                            .border(Color.gray, width: 1)
    //                            .textFieldStyle(.roundedBorder)
//                                .submitLabel(.send)
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
        }
        .background(Color.gray.opacity(0.5))
        .onTapGesture {
//            dismissAction()
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
