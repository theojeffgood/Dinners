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
    @ObservedObject var shareTools: ShareCoordinator = ShareCoordinator.shared
    
    @State private var showShareSheet = false
    @State private var cannotShare = false
    var onDismiss: () -> Void
    var userOwnsShare: Bool{
        return (!UserDefaults.standard.bool(forKey: "inAHousehold") ||
                UserDefaults.standard.bool(forKey: "isHouseholdOwner"))
    }
    
    var userIsParticipant: Bool{
        return (UserDefaults.standard.bool(forKey: "inAHousehold") &&
                !UserDefaults.standard.bool(forKey: "isHouseholdOwner"))
    }
    
    var body: some View {
        NavigationStack{
            VStack{
                List{
                    if let share = shareTools.activeShare{
                        let participants = share.participants.sorted { $0.acceptanceStatus != .pending && $1.acceptanceStatus == .pending }
                        
                        ForEach(participants) { participant in
                            UserCard(name: participant.name(in: share), status: participant.acceptanceStatus)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.white)
                                .if(share.currentUserParticipant == share.owner &&
                                    share.currentUserParticipant != participant){ view in
                                    view.swipeActions(allowsFullSwipe: false) {
                                        Button(role: .destructive) { share.removeParticipant(participant) }
                                    label: { Label("Remove from household", systemImage: "trash.fill") }
                                    }
                                }
                        }
                    } else { ZStack{ UserCard(name: "You", status: .accepted) } }
                    
                    ForEach(0..<2){ i in
                        let numOfParticipants = (shareTools.activeShare?.participants.count ?? 1)
                        ShareButton(memberNumber: numOfParticipants + i + 1){
                            if userOwnsShare{ share() }
                            else { cannotShare.toggle() }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.white)
                }
                .scrollContentBackground(.hidden)
                    
                if userIsParticipant{
                    Button("Leave household") {
                        Task{ await shareTools.leaveShare() } //animate?
                    }.padding(.bottom, 30)
                     .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Household")
        }
        
        .onAppear{ shareTools.fetchActiveShare() }
        .sheet(isPresented: $showShareSheet, onDismiss: { shareTools.fetchActiveShare() }) {
            if let share = shareTools.activeShare{
                CloudSharingView(share: share)
            } else{ ShareFailed() }
        }
        .sheet(isPresented: $cannotShare) {
            CannotShare()
        }
    }
}

extension Household{
    func share(){
        if let share = shareTools.activeShare{
            if share.currentUserParticipant == share.owner{
                showShareSheet = true
            }
            
        } else{ //** Share doesn't exist **//
            Task {
                do {
                    try await shareTools.getShare()
                    showShareSheet = true
                    
                    UserDefaults.standard.set(true, forKey: "inAHousehold")
                    UserDefaults.standard.set(true, forKey: "isHouseholdOwner")
                } catch {
                    showShareSheet = true // Shows friendly error. Not share sheet.
                    Logger.sharing.error("Household failed to get share: \(error, privacy: .public).")
                }
            }
        }
    }
}

extension CKShare.Participant{
    func name(in share: CKShare) -> String{
        if self == share.currentUserParticipant{
            return "You"
        } else if self.acceptanceStatus == .pending{
            return "Invite sent"
        } else if let name = self.userIdentity.nameComponents?.givenName{
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
    private var memberNumber: Int
    private var showShareSheet: () -> Void
    
    init(memberNumber: Int, showShareSheet: @escaping () -> Void) {
        self.memberNumber   = memberNumber
        self.showShareSheet = showShareSheet
    }
    
    var body: some View{
        VStack(spacing: 0){
            Button(action: {
                showShareSheet()
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
                        Text("Add member \(memberNumber)")
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

