//
//  ContentView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI

struct ContentView: View {
    var rejectAction: () -> ()?
    var acceptAction: () -> ()?
    
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Filter")
                    .frame(maxWidth: .infinity,
                           alignment: .leading)
                    .font(.title3)
                    .foregroundColor(.gray)
                Spacer()
                
                HStack() {
                    Button(action: {
                        print("matches tapped")
                    }) {
                        Text("Matches")
                            .frame(width: 100, height: 35)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.black, lineWidth: 1)
                                )
                    }
                    Button(action: {
                        print("likes tapped")
                    }) {
                        Text("Likes")
                            .frame(width: 100, height: 35)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.black, lineWidth: 1)
                                )
                    }
                    Button(action: {
                        print("dislikes tapped")
                    }) {
                        Text("Dislikes")
                            .frame(width: 100, height: 35)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.black, lineWidth: 1)
                                )
                    }
                    Spacer()
                }
                
                Spacer()
                Spacer()
                Spacer()
                
                VStack(spacing: 0) {
                    AsyncImage(url: URL(string: "https://halflemons-media.s3.amazonaws.com/2501.jpg")) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 300)
                    } placeholder: {
                        ProgressView()
                    }
                        .cornerRadius(15, corners: [.topLeft, .topRight])
                        .frame(maxWidth: .infinity)
                        .shadow(radius: 20)
                    
                    Text("Chicken Cacciatore")
                        .padding(.leading)
                        .frame(maxWidth: .infinity,
                               maxHeight: 100,
                               alignment: .leading)
                        .background(.white)
                        .font(.title2)
//                        .cornerRadius(15)
                        .cornerRadius(15, corners: [.bottomLeft, .bottomRight])
                        .shadow(radius: 20)
                }
                
                HStack {
                    Button(action: {
                        rejectAction()
                    }) {
                        Text("X")
                            .frame(width: 90, height: 90)
                            .background(Color.red)
                            .foregroundColor(.black)
                            .cornerRadius(45)
                            .font(.largeTitle)
                            .shadow(radius: 25)
                    }
                    Spacer()
                    Button(action: {
                        acceptAction()
                    }) {
                        Text("✓")
                            .frame(width: 90, height: 90)
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(45)
                            .font(.largeTitle)
                            .shadow(radius: 25)
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("FryDay")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(rejectAction: {}, acceptAction: {})
    }
}


//MARK: -- Extensions


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
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
