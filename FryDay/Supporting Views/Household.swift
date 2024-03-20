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
        
    @State private var currentPresentationDetent: PresentationDetent = .height(225)
    let presentationDetents: [PresentationDetent] = [.height(225), .height(325)]
    
    var body: some View {
        VStack(spacing: 30){
            HStack(spacing: 7){
                Image(systemName: "house.fill")
                    .resizable()
                    .frame(width: 25, height: 25)
                Text("Household")
                    .font(.system(size: 30, weight: .bold))
                Spacer()
            }
            
            if let share = shareCoordinator.existingShare{
                LazyVGrid(columns: [GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())]) {
                    ForEach(share.participants) { participant in
                        
                        VStack(spacing: 0){
                            ZStack{
                                Circle().frame(width: 80, height: 80)
                                Text("😎").font(.system(size: 45))
                                
                                let userIsShareOnwer  = (share.currentUserParticipant == share.owner)
                                let userIsParticipant = (share.currentUserParticipant == participant)
                                if userIsShareOnwer || userIsParticipant{
                                    Button(action: {
                                        withAnimation {
                                            if userIsShareOnwer { share.removeParticipant(participant) }
                                            else if userIsParticipant{ Task{ await shareCoordinator.removeSelf() } }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .resizable()
                                            .foregroundColor(.red)
                                    }
                                    .offset(x: 32, y: -32)
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
                    
                    if !UserDefaults.standard.bool(forKey: "inAHousehold") ||
                        UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
                        VStack(spacing: 0){
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
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            }
                            Text("Add peeps")
                        }
                    }
                }
            }
        }
        .padding()

        .onAppear(){ shareCoordinator.fetchExistingShare() }
        .sheet(isPresented: $showShareSheet, content: {
            if let share = shareCoordinator.existingShare,
               share.currentUserParticipant?.role == .owner{
                CloudSharingView(share: share)
                    .onDisappear { shareCoordinator.fetchExistingShare() }
            }
        })

        .presentationDetents(Set<PresentationDetent>(presentationDetents), selection: $currentPresentationDetent)
        .presentationDragIndicator(.hidden)
        .onChange(of: shareCoordinator.existingShare) { newValue in
            let participants = (newValue?.participants.count ?? 0)
            let sheetHeight: PresentationDetent = (participants > 2) ? .height(325) : .height(225)
            currentPresentationDetent = sheetHeight
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
