//
//  Household.swift
//  FryDay
//
//  Created by Theo Goodman on 1/22/23.
//

import SwiftUI
//import MessageUI
import CloudKit
import OSLog

struct Household: View {
    
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var shareCoordinator: ShareCoordinator = ShareCoordinator.shared
    
    @State private var showShareSheet = false
    var onDismiss: () -> Void
    var userCanShare: Bool{
        return (!UserDefaults.standard.bool(forKey: "inAHousehold") ||
                UserDefaults.standard.bool(forKey: "isHouseholdOwner"))
    }
    
    var userIsShareMember: Bool{
        return (UserDefaults.standard.bool(forKey: "inAHousehold") &&
                !UserDefaults.standard.bool(forKey: "isHouseholdOwner"))
    }
    
    var body: some View {
        NavigationStack{
            VStack{
                List{
                    if let share = shareCoordinator.existingShare{
                        let participants = share.participants.sorted { $0.acceptanceStatus != .pending && $1.acceptanceStatus == .pending }
                        
                        ForEach(participants) { participant in
                            let name = getName(for: participant, in: share)
                            UserCard(name: name, status: participant.acceptanceStatus)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.white)
                                .swipeActions(allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        let userIsShareOnwer = (share.currentUserParticipant == share.owner)
                                        if  userIsShareOnwer   {share.removeParticipant(participant) }
                                    } label: { Label("Remove from household", systemImage: "trash.fill") }
                                }
                        }
                    } else { ZStack{ UserCard(name: "You", status: .accepted) } }
                    
                    if userCanShare{
                        ForEach(0..<2){ i in
                            ShareButton(getShare: shareCoordinator.getShare,
                                        shareExists: (shareCoordinator.existingShare != nil),
                                        showShareSheet: $showShareSheet )
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                    }
                }
                .scrollContentBackground(.hidden)
                    
//                if userIsShareMember{
                Button(action: {
                    Task{ await shareCoordinator.removeSelf() } //animate?
                }) {
                    Text("Leave household")
                        .foregroundStyle(.blue)
                        .padding(.bottom, 30)
                }
            }
            .navigationTitle("Household")
        }
        
        .onAppear{ shareCoordinator.fetchExistingShare() }
        .sheet(isPresented: $showShareSheet, content: {
            if let share = shareCoordinator.existingShare{
//                share.currentUserParticipant?.role == .owner{
                CloudSharingView(share: share).onDisappear { shareCoordinator.fetchExistingShare() }
                
            } else{ ShareErrorView() }
        })
    }
}

extension Household{
    
    func getName(for participant: CKShare.Participant,
                 in share: CKShare) -> String{
        if participant == share.currentUserParticipant{
            return "You"
        } else if participant.acceptanceStatus == .pending{
            return "Invite sent"
        } else if let name = participant.userIdentity.nameComponents?.givenName{
            return name
        }
        return "Chef"
    }
}

struct Household_Previews: PreviewProvider {
    
    static var previews: some View {
        Household(onDismiss: {})
    }
}


//** MARK: -- RELATED VIEWS **//

struct UserCard: View {
    
    private let name: String
    private let symbol: String
    
    init(name: String, status: CKShare.ParticipantAcceptanceStatus) {
        self.name = name
        symbol = (status == .pending) ? "✉️" : "😎"
    }
    
    var body: some View{
        ZStack{
            RoundedRectangle(cornerRadius: 15)
                .stroke(.white)
                .overlay(content: { RoundedRectangle(cornerRadius: 15).stroke(Color.init(hex: 0xE8EAEA), lineWidth: 1) })
                .frame(height: 100)
            HStack(spacing: 15){
                Text(symbol)
                    .font(.system(size: 45))
                Text(name)
                    .font(.custom("Solway-regular", size: 24))
                    .foregroundStyle(.black)
                Spacer()
            }.padding(.leading, 20)
        }
    }
}

struct ShareButton: View {
    private var getShare: () async throws -> Void
    private var shareExists: Bool
    @Binding var showShareSheet: Bool
    
    init(getShare: @escaping () async throws -> Void, shareExists: Bool, showShareSheet: Binding<Bool>) {
        self.getShare = getShare
        self.shareExists = shareExists
        self._showShareSheet = showShareSheet
    }
    
    var body: some View{
        VStack(spacing: 0){
            Button(action: {
                if shareExists{ showShareSheet = true }
                else{
                    Task {
                        do {
                            try await getShare()
                            showShareSheet = true
                        } catch { Logger.sharing.error("Household failed to get share.") }
                    }
                }
                UserDefaults.standard.set(true, forKey: "inAHousehold")
                UserDefaults.standard.set(true, forKey: "isHouseholdOwner")
            }) {
                ZStack{
                    RoundedRectangle(cornerRadius: 15)
                        .frame(height: 100)
                        .foregroundColor(Color.init(hex: 0xE8EAEA))
                        .shadow(radius: 5)
                    HStack(spacing: 15){
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text("Add a member")
                            .font(.custom("Solway-regular", size: 24))
                        Spacer()
                    }.foregroundStyle(.gray)
                    .padding(.leading, 25)
                }
            }
        }
    }
}



////MARK: -- // SEND AN INVITATION //
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
