//
//  Household.swift
//  FryDay
//
//  Created by Theo Goodman on 1/22/23.
//

import SwiftUI

struct Household: View {
    @State private var loggedIn: Bool = false
    
    var body: some View {
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
                Text("You must login to\n create a household")
                    .font(.system(size: 20))
                Button("  Sign in with Apple               ") {
                    withAnimation {
                        loggedIn = true
                    }
                }
                .padding()
                .background(Color.black)
                .cornerRadius(30)
                .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .multilineTextAlignment(.center)
        .background(Color.blue)
        .cornerRadius(25)
    }
}

struct Household_Previews: PreviewProvider {
    static var previews: some View {
        Household()
            .previewLayout(.sizeThatFits)
    }
}
