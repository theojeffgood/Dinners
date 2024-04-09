//
//  SharePermissionsErrorView.swift
//  Dinners
//
//  Created by Theo Goodman on 4/9/24.
//

import SwiftUI

struct SharePermissionsErrorView: View {
    
    var body: some View {
        VStack{
            Text("😬")
                .fontWeight(.bold)
                .font(.largeTitle)
                .padding(.bottom, 35)
            Text("Only the household owner can add new members.")
                .multilineTextAlignment(.center)
                .font(.title3)
        }.padding(.horizontal)
    }
}

#Preview {
    SharePermissionsErrorView()
}
