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
    @State private var showSharePermissionsError = false
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
                    if let share = shareCoordinator.existingShare{
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
                        ShareButton(){
                            if userOwnsShare{ share() }
                            else { showSharePermissionsError.toggle() }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.white)
                }
                .scrollContentBackground(.hidden)
                    
                if userIsParticipant{
                    Button("Leave household") {
                        Task{ await shareCoordinator.removeSelf() } //animate?
                    }.padding(.bottom, 30)
                     .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Household")
        }
        
        .onAppear{ shareCoordinator.fetchExistingShare() }
        .sheet(isPresented: $showShareSheet, onDismiss: { shareCoordinator.fetchExistingShare() }) {
            if let share = shareCoordinator.existingShare{
                CloudSharingView(share: share)
            } else{ ShareErrorView() }
        }
        .sheet(isPresented: $showSharePermissionsError) {
            SharePermissionsErrorView()
        }
    }
}

extension Household{
    func share(){
        if let share = shareCoordinator.existingShare{
            if share.currentUserParticipant == share.owner{
                showShareSheet = true
            }
            
        } else{
            Task {
                do {
                    try await shareCoordinator.getShare()
                    showShareSheet = true
                    
                    UserDefaults.standard.set(true, forKey: "inAHousehold")
                    UserDefaults.standard.set(true, forKey: "isHouseholdOwner")
                } catch {
                    showShareSheet = true // This will show friendly user error. Not share sheet.
                    Logger.sharing.error("Household failed to get share.")
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
    private var showShareSheet: () -> Void
    
    init(showShareSheet: @escaping () -> Void) {
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

