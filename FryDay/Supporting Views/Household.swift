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
//    @EnvironmentObject private var shareCoordinator: ShareCoordinator
    @ObservedObject var shareCoordinator: ShareCoordinator = ShareCoordinator.shared
    private let stack = DataController.shared
    
    @State private var showShareSheet = false
    var onDismiss: () -> Void
//    if let currentUser = share.currentUserParticipant, currentUser == share.owner {
//        return true
//    }
    
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
                        if let share = ShareCoordinator.shared.existingShare{
                            let shareParticipants = share.participants
                            ForEach(shareParticipants) { participant in
                                VStack(spacing: 5){
                                    ZStack{
                                        Circle()
                                            .padding([.leading, .trailing])
                                        Text("😎")
                                            .font(.system(size: 45))
                                        Button(action: {
                                            withAnimation {
                                                share.removeParticipant(participant)
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .resizable()
                                                .foregroundColor(.red)
                                        }
                                        .offset(x: 30, y: -30)
                                        .frame(width: 25, height: 25)
                                    }
                                    
                                    if participant.role == .owner ||
                                        participant.acceptanceStatus == .accepted{
                                        let title = participant.userIdentity.nameComponents?.givenName ?? "Chef"
                                        Text(title)
                                    } else if participant.acceptanceStatus == .pending{
                                        Text("Invite sent")
                                    }
                                }
                            }
                        }
                        
                        if !UserDefaults.standard.bool(forKey: "inAHousehold") ||
                            UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
                            
                            VStack(spacing: 5){
                                Button(action: {
                                    if ShareCoordinator.shared.existingShare == nil{
                                        Task {
                                            do {
                                                try await ShareCoordinator.shared.getShare()
                                                showShareSheet = true
                                            } catch { /*showShareError()*/ }
                                        }
                                    } else{
                                        showShareSheet = true
                                    }
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
            if let share = ShareCoordinator.shared.existingShare,
               share.currentUserParticipant?.role == .owner{
                CloudSharingView(share: share, container: stack.ckContainer)
                    .onDisappear { ShareCoordinator.shared.fetchExistingShare() }
            }
        })
        .onAppear(){
            ShareCoordinator.shared.fetchExistingShare()
        }
    }
}

struct Household_Previews: PreviewProvider {
    
    static var previews: some View {
        Household(onDismiss: {})
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
