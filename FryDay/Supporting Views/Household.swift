//
//  Household.swift
//  FryDay
//
//  Created by Theo Goodman on 1/22/23.
//

import SwiftUI
//import MessageUI
import CloudKit

struct Household: View {
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var shareCoordinator: ShareCoordinator
    private let stack = DataController.shared
    
    @State private var share: CKShare?
    @State var householdMembers: [CKShare.Participant] = [] /*<-- or use this?*/
    @State private var showShareSheet = false
    var onDismiss: () -> Void
//    if let currentUser = share.currentUserParticipant, currentUser == share.owner {
//        return true
//    }
        
    init(share: CKShare?, onDismiss: @escaping () -> Void){
        self.share = share
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: -15){
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .onTapGesture {
                    onDismiss()
                }
            VStack(spacing: 30){
                HStack(spacing: 7){
                    Image(systemName: "house.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                    Text("Household")
                        .font(.system(size: 30, weight: .bold))
                    Spacer()
                }
                
                    HStack(spacing: 10){
                        ForEach(householdMembers) { member in
                            VStack(spacing: 5){
                                ZStack{
                                    Circle()
                                        .padding([.leading, .trailing])
                                    Text(image(for: member.role))
                                        .font(.system(size: 45))
                                    Button(action: {
                                        withAnimation {
                                                shareCoordinator.existingShare?.removeParticipant(member)
//                                            if householdMembers.isEmpty{}
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .resizable()
                                            .foregroundColor(.red)
                                    }
                                    .offset(x: 30, y: -30)
                                    .frame(width: 25, height: 25)
                                }
                                
                                if member.role == .owner ||
                                    member.acceptanceStatus == .accepted{
                                    let title = member.userIdentity.nameComponents?.givenName ?? "Chef"
                                    Text(title)
                                } else if member.acceptanceStatus == .pending{
                                    Text("Invite sent")
                                }
                            }
                        }
                        
                        if !UserDefaults.standard.bool(forKey: "inAHousehold") ||
                            UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
                            
                            VStack(spacing: 5){
                                Button(action: {
                                    if share == nil{
                                        Task {
                                            self.share = try await shareCoordinator.createShare()
                                        }
                                    }
                                    showShareSheet = true
                                    
                                    UserDefaults.standard.set(true, forKey: "inAHousehold")
                                    UserDefaults.standard.set(true, forKey: "isHouseholdOwner")
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 75, height: 75)
                                        .foregroundColor(.gray)
                                }
                                Text("Add peeps")
                            }
                        }
                        
                        Spacer()
                    }.frame(height: 100)
                    

            }
            .padding()
            .padding(.bottom)
            .background(Color.white)
            .cornerRadius(20)
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showShareSheet, content: {
            if let share = share,
               share.currentUserParticipant?.role == .owner{
                CloudSharingView(share: share, container: stack.ckContainer)
            }
        })
        .onAppear(){
            self.householdMembers = shareCoordinator.getParticipants(share: share)
        }
    }
}

struct Household_Previews: PreviewProvider {
    
    
    static var previews: some View {
        Household(share: nil, onDismiss: {})
    }
}

// MARK: -- Returns CKShare participant permission, methods and properties to share

extension Household {
    private func string(for permission: CKShare.ParticipantPermission) -> String {
        switch permission {
        case .unknown:
            return "Unknown"
        case .none:
            return "None"
        case .readOnly:
            return "Read-Only"
        case .readWrite:
            return "Read-Write"
        @unknown default:
            fatalError("A new value added to CKShare.Participant.Permission")
        }
    }
    
    private func string(for role: CKShare.ParticipantRole) -> String {
        switch role {
        case .owner:
            return "Owner"
        case .privateUser:
            return "Private User"
        case .publicUser:
            return "Public User"
        case .unknown:
            return "Unknown"
        @unknown default:
            fatalError("A new value added to CKShare.Participant.Role")
        }
    }
    
    private func string(for acceptanceStatus: CKShare.ParticipantAcceptanceStatus) -> String {
        switch acceptanceStatus {
        case .accepted:
            return "Accepted"
        case .removed:
            return "Removed"
        case .pending:
            return "Invited"
        case .unknown:
            return "Unknown"
        @unknown default:
            fatalError("A new value added to CKShare.Participant.AcceptanceStatus")
        }
    }
    
    private func image(for role: CKShare.ParticipantRole) -> String {
        switch role {
        case .owner:
            return "😎"
        case .privateUser:
            return "😎"
        case .publicUser:
            return "😎"
        case .unknown:
            return "🥳"
        @unknown default:
            fatalError("A new value added to CKShare.Participant.Role")
        }
    }
}





////MARK: -- // SEND AN INVITATION //
//                case .addMember:
//                    VStack(spacing: 15){
//                        Text("Send invitation")
//                            .font(.system(size: 22, weight: .medium))
//                            .multilineTextAlignment(.center)
//                        HStack(spacing: 50){
//                            VStack{
//                                Button(action: {
//                                    ShareHelper.shared.sendText(){
//                                        handleInviteSent()
//                                    }
//                                }) {
//                                    Image("imessage")
//                                }
//                                Text("iMessage")
//                            }
//                            VStack{
//                                Button(action: {
//                                    ShareHelper.shared.sendWhatsApp()
//                                    handleInviteSent()
//                                }) {
//                                    Image("whatsapp")
//                                }
//                                Text("WhatsApp")
//                            }
//                            VStack{
//                                Button(action: {
//                                    ShareHelper.shared.sendEmail(){
//                                        handleInviteSent()
//                                    }
//                                }) {
//                                    Image("email")
//                                }
//                                Text("Email")
//                            }
//                        }
//                        .padding([.bottom])
//                    }
