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
    @ObservedObject var shareCoordinator: ShareCoordinator = ShareCoordinator.shared
    
    @State private var showShareSheet = false
    var onDismiss: () -> Void
    
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
                        if let share = shareCoordinator.existingShare{
                            ForEach(share.participants) { participant in
                                VStack(spacing: 5){
                                    ZStack{
                                        Circle().padding(.horizontal)
                                        Text("😎").font(.system(size: 45))
                                        
                                        if participant.hasPermissions(in: share){
                                            Button(action: {
                                                withAnimation {
                                                    if participant.role == .owner {
                                                        share.removeParticipant(participant)
                                                    } else if participant == share.currentUserParticipant{
                                                        Task{ await shareCoordinator.removeSelf() }
                                                    }
                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.red)
                                            }
                                            .offset(x: 30, y: -30)
                                            .frame(width: 25, height: 25)
                                        }
                                    }
                                    
                                    if participant == share.currentUserParticipant{
                                        Text("You")
                                    } else if participant.acceptanceStatus == .pending{
                                        Text("Invite sent")
                                    } else if let title = participant.userIdentity.nameComponents?.givenName{
                                        Text(title)
                                    }
                                }
                            }
                        }
                        
                        if !UserDefaults.standard.bool(forKey: "inAHousehold") ||
                            UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
                            
                            VStack(spacing: 5){
                                Button(action: {
                                    if shareCoordinator.existingShare == nil{
                                        Task {
                                            do {
                                                try await shareCoordinator.getShare()
                                                showShareSheet = true
                                            } catch { /*showShareError()*/ }
                                        }
                                    } else{ showShareSheet = true }
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
        .onAppear(){ shareCoordinator.fetchExistingShare() }
        .sheet(isPresented: $showShareSheet, content: {
            if let share = shareCoordinator.existingShare,
               share.currentUserParticipant?.role == .owner{
                CloudSharingView(share: share)
                    .onDisappear { shareCoordinator.fetchExistingShare() }
            }
        })
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
