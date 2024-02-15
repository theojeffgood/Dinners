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

//extension View{
//    func rejectStyle() -> some View{
//        //X-MARK
//        self
//            .frame(width: 90, height: 90)
//            .background(Color.red) // red
//            .foregroundColor(.white) // white text
//            .cornerRadius(45)
//            .font(.system(size: 48, weight: .bold))
//            .shadow(radius: 25)
//    }
//    
//    func acceptStyle() -> some View{
//        //CHECK-MARK
//        self
//            .frame(width: 90, height: 90)
//            .background(Color.green) // green
//            .foregroundColor(.black) // black text
//            .cornerRadius(45)
//            .font(.system(size: 48, weight: .heavy))
//            .shadow(radius: 25)
//    }
//}

import OSLog

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like a view that appeared.
    static let sharing = Logger(subsystem: subsystem, category: "sharing")

    /// All logs related to tracking and analytics.
//    static let statistics = Logger(subsystem: subsystem, category: "statistics")
}
