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

//adapted from: https://www.swiftwithvincent.com/blog/bad-practice-not-using-a-buttonstyle
struct FilterButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        
            .labelStyle(.titleAndIcon) // .titleAndIcon crashes app
            .font(.custom("Solway-Light", size: 16))
            .foregroundColor(.black)
            .padding(.vertical, 10)
            .padding(.horizontal)
            .cornerRadius(20, corners: .allCorners)
            .overlay(content: {
                RoundedRectangle(cornerRadius: 20).stroke(Color.init(hex: 0xE8EAEA), lineWidth: 1)
            })
//            .background(configuration.isPressed ? .blue.opacity(0.5) : .blue)
    }
}

struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct ActionButtons: View {
    var action: (CGSize) -> Void
    private let leftSwipe: CGSize = CGSize(width: -300, height: 0)
    private let rightSwipe: CGSize = CGSize(width: 300, height: 0)
    
    var body: some View{
        HStack() {
//            VStack(alignment: .trailing) {
                Button(action: { action( leftSwipe ) }) {
                    VStack(alignment: .leading, spacing: 0) {
                        Image(.voteNay)
                            .resizable()
                            .tint(.white)
                            .frame(width: 75, height: 75)
                        Text("Nay!")
                            .foregroundColor(.white)
                            .font(.custom("Solway-Bold", size: 36))
                            .padding(.leading, 7)
                    }
                }
//            }
            Spacer()
//            VStack(alignment: .leading) {
                Button(action: { action( rightSwipe ) }) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Image(.voteYay)
                            .resizable()
                            .tint(.white)
                            .frame(width: 75, height: 75)
                        Text("Yay!")
                            .foregroundColor(.white)
                            .font(.custom("Solway-Bold", size: 36))
                            .padding(.trailing, 5)
                    }
                }
//            }
        }
//        .padding([.leading, .trailing], 1)
     }
 }

//Adapted from: https://stackoverflow.com/a/58216967/13551385
extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension Collection {
    func count(where test: (Element) throws -> Bool) rethrows -> Int {
        return try self.filter(test).count
    }
}

/// Allows to match for optionals with generics that are defined as non-optional.
public protocol AnyOptional {
    /// Returns `true` if `nil`, otherwise `false`.
    var isNil: Bool { get }
}
extension Optional: AnyOptional {
    public var isNil: Bool { self == nil }
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

    /// Logs the events related to sharing.
    static let sharing = Logger(subsystem: subsystem, category: "sharing")

    /// Logs the events related to in app purchases.
    static let store = Logger(subsystem: subsystem, category: "appstore")
    
    /// Logs the events related to in app purchases.
    static let recipe = Logger(subsystem: subsystem, category: "recipe")
}

//MARK: -- CONDITIONAL VIEW MODIFIERS: https://www.avanderlee.com/swiftui/conditional-view-modifier/

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

//extension Bool {
//    static var iOS16dot4: Bool {
//         guard #available(iOS 16.4, *) else {
//             // It's iOS 13 so return true.
//             return false
//         }
//         // It's iOS 14 so return false.
//         return true
//     }
// }
