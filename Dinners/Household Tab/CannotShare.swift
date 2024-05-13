//
//  CannotShare.swift
//  Dinners
//
//  Created by Theo Goodman on 4/9/24.
//

import SwiftUI

struct CannotShare: View {
    
    var body: some View {
        VStack{
            Text("😬")
                .fontWeight(.bold)
                .font(.largeTitle)
                .padding(.bottom, 35)
            Text("Only the owner of a household can add members.")
                .multilineTextAlignment(.center)
                .font(.title3)
        }.padding(.horizontal)
    }
}

#Preview {
    CannotShare()
}
