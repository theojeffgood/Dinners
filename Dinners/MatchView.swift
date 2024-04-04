//
//  MatchView.swift
//  FryDay
//
//  Created by Theo Goodman on 3/28/24.
//

import SwiftUI

struct MatchView: View {
    
    var body: some View{
//        ZStack {
            VStack(alignment: .center, content: {
                Text("Boom!")
                    .kerning(3.5)
//                    .font(.title)
                    .font(.system(size: 75, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.bottom, 45)
                Text("You matched")
                    .kerning(2.0)
//                    .font(.title3)
                    .font(.system(size: 35, weight: .bold))
                    .foregroundStyle(.black)
//                Text("🎉")
//                    .font(.system(size: 55, weight: .bold))
//                    .font(.title)
            })
            .padding(.bottom, 75)
//        }
//        .frame(width: 250, height: 350)
//        .background(.white)
//        .cornerRadius(20, corners: .allCorners)
//        .overlay(RoundedRectangle(cornerRadius: 20)
//            .stroke(.black, lineWidth: 2)
//        )
    }
}

#Preview {
    MatchView()
}
