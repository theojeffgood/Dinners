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
    let threeColumns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        VStack(spacing: 30){
            HStack(spacing: 7){
                Image(systemName: "house.fill")
                    .resizable()
                    .frame(width: 25, height: 25)
                Text("Household")
                    .font(.custom("Solway-Regular", size: 30))
                Spacer()
            }
            
            LazyVGrid(columns: threeColumns) {
                if let share = shareCoordinator.existingShare{
                    let participants = share.participants.sorted { $0.acceptanceStatus != .pending && $1.acceptanceStatus == .pending }
                    ForEach(participants) { participant in
                        
                        VStack(spacing: 0){
                            ZStack{
                                UserCard(status: participant.acceptanceStatus)
                                
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
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(.red)
                                    }.offset(x: 32, y: -32)
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
                } else{
                    VStack(spacing: 0){
                        UserCard(status: .accepted)
                        Text("You")
                    }
                }
                
                if !UserDefaults.standard.bool(forKey: "inAHousehold") ||
                    UserDefaults.standard.bool(forKey: "isHouseholdOwner"){
                    ShareButton(getShare: shareCoordinator.getShare,
                                shareExists: (shareCoordinator.existingShare != nil),
                                showShareSheet: { showShareSheet = true })
                }
            }
        }
        .padding()

        .onAppear(){ shareCoordinator.fetchExistingShare() }
        .sheet(isPresented: $showShareSheet, content: {
            if let share = shareCoordinator.existingShare{
//               share.currentUserParticipant?.role == .owner{
                CloudSharingView(share: share).onDisappear { shareCoordinator.fetchExistingShare() }
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

struct UserCard: View {
    
    private let color: Color
    private let symbol: String
    
    init(status: CKShare.ParticipantAcceptanceStatus) {
        color  = (status == .pending) ? .white : .black
        symbol = (status == .pending) ? "✉️" : "😎"
    }
    
    var body: some View{
        ZStack{
            Circle()
                .strokeBorder(.black,lineWidth: 2)
                .background(Circle().foregroundColor(color))
                .frame(width: 80, height: 80)
            Text(symbol)
                .font(.system(size: 45))
        }
    }
}

struct ShareButton: View {
    private var getShare: () async throws -> Void
    private var shareExists: Bool
    private var showShareSheet: () -> Void
    
    init(getShare: @escaping () async throws -> Void, shareExists: Bool, showShareSheet: @escaping () -> Void) {
        self.getShare = getShare
        self.shareExists = shareExists
        self.showShareSheet = showShareSheet
    }
    
    var body: some View{
        VStack(spacing: 0){
            Button(action: {
                if !shareExists{
                    Task {
                        do {
                            try await getShare()
//                            try await shareCoordinator.getShare()
                            showShareSheet()
                        } catch { /*showShareError()*/ }
                    }
                } else{ showShareSheet() }
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
