//
//  MatchView.swift
//  FryDay
//
//  Created by Theo Goodman on 3/28/24.
//

import SwiftUI

struct MatchView: View {
    
    @Binding var play: Bool
    
    var body: some View{
            VStack(alignment: .center, content: {
                Text("Boom!")
                    .kerning(3.5)
                    .font(.system(size: 75, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.bottom, 45)
                Text("You matched")
                    .kerning(2.0)
                    .font(.system(size: 35, weight: .bold))
                    .foregroundStyle(.black)
            })
            .padding(.bottom, 75)
            .opacity(play ? 1.0 : 0.0)
            .animation(.easeInOut, value: play)
            .onChange(of: play, perform: { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    play = false
                }
            })
    }
}

#Preview {
    MatchView(play: .constant(false))
}
