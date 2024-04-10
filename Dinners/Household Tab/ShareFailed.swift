//
//  ShareFailed.swift
//  Dinners
//
//  Created by Theo Goodman on 4/5/24.
//

import SwiftUI

struct ShareFailed: View {
    var body: some View {
        VStack{
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .resizable()
                .frame(width: 150, height: 150)
            Text("Share failed")
                .fontWeight(.bold)
                .font(.largeTitle)
                .padding(.bottom, 35)
            Text("Check that you're signed in to your Apple ID. \n And you're connected to the web.")
                .multilineTextAlignment(.center)
                .font(.title3)
        }.padding(.horizontal)
    }
}

#Preview {
    ShareFailed()
}
