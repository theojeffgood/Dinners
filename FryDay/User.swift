//
//  User.swift
//  FryDay
//
//  Created by Theo Goodman on 2/15/23.
//

import Foundation

struct User: Identifiable {
    var id = UUID()
    var userType: UserType = .pending
    
    enum UserType {
        case member
        case pending
        
        var text: String{
            switch self {
            case .member:
                return "You"
            case .pending:
                return "Pending"
            }
        }
        
        var image: String{
            switch self {
            case .member:
                return "😎"
            case .pending:
                return "🥳"
            }
        }
    }
}

extension User{
    mutating func save(){
        
    }
    
    mutating func delete(){
        
    }
}
