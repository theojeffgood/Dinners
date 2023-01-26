//
//  Household.swift
//  FryDay
//
//  Created by Theo Goodman on 1/22/23.
//

import SwiftUI

struct Household: View {
    @State private var loggedIn: Bool = false
    var dismissAction: () -> Void
    
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
                    
                    switch loggedIn{
                    case true:
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
                                ZStack{
                                    Circle()
                                        .padding([.leading, .trailing])
                                    Image(systemName: "plus")
                                        .resizable()
                                        .frame(width: 45, height: 45)
                                        .foregroundColor(.white)
                                }
                                Text("Add a member")
                            }
                            Spacer()
                        }.frame(height: 100)
                        
                    case false:
                        Text("Please sign in to\n create a household.")
                            .font(.system(size: 20))
                            .multilineTextAlignment(.center)
                        Button("  Sign in with Apple            ") {
                            withAnimation {
                                loggedIn = true
                            }
                        }
                        .font(.system(size: 20))
                        .padding()
                        .background(Color.black)
                        .cornerRadius(30)
                        .foregroundColor(.white)
                    }
                }
                .padding()
                .padding(.bottom)
                .background(Color.white)
                .cornerRadius(20)
            }
        }
        .background(Color.gray.opacity(0.5))
        .ignoresSafeArea()
        .onTapGesture {
            dismissAction()
        }
    }
}

struct Household_Previews: PreviewProvider {
    static var previews: some View {
        Household(dismissAction: {})
        //            .previewLayout(.sizeThatFits)
    }
}
