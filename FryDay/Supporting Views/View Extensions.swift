//
//  View Extensions.swift
//  FryDay
//
//  Created by Theo Goodman on 12/11/23.
//

import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    
//    func stacked(at position: Int, in total: Int) -> some View {
//        let offset = Double(total - position)
//        return self.offset(x: 0, y: offset * 9)
//    }
}

struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View{
    func rejectStyle() -> some View{
        //X-MARK
        self
            .frame(width: 90, height: 90)
            .background(Color.red) // red
            .foregroundColor(.white) // white text
            .cornerRadius(45)
            .font(.system(size: 48, weight: .bold))
            .shadow(radius: 25)
    }
    
    func acceptStyle() -> some View{
        //CHECK-MARK
        self
            .frame(width: 90, height: 90)
            .background(Color.green) // green
            .foregroundColor(.black) // black text
            .cornerRadius(45)
            .font(.system(size: 48, weight: .heavy))
            .shadow(radius: 25)
    }
}

struct LikesAndMatches: View {
    var matches: [Recipe] = []
    var likes: [Recipe] = []
    
    var body: some View{
        HStack() {
            NavigationLink(
                destination: RecipesList(recipesType: "Matches",
                                         recipes: matches),
                label: {
                    Text("❤️ Matches")
                        .frame(width: 125, height: 45)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                })
            
            NavigationLink(
                destination: RecipesList(recipesType: "Likes",
                                         recipes: likes),
                label: {
                    Text("👍 Likes")
                        .frame(width: 125, height: 45)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                })
            Spacer()
        }
    }
}
