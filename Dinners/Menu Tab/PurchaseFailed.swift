//
//  PurchaseFailed.swift
//  Dinners
//
//  Created by Theo Goodman on 4/23/24.
//

import SwiftUI

struct PurchaseFailed: View {
    
    var body: some View {
        VStack{
            Text("😬")
                .fontWeight(.bold)
                .font(.largeTitle)
                .padding(.bottom, 35)
            Text("Purchase failed. Please check your Apple ID and try again.")
                .multilineTextAlignment(.center)
                .font(.title3)
        }.padding(.horizontal)
    }
}

#Preview {
    PurchaseFailed()
}
