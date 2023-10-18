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
//    @FetchRequest(sortDescriptors: []) var users: FetchedResults<User>
    @State var householdMembers: [CKShare.Participant] = []
    
    @State private var share: CKShare?
//    @ObservedObject var recipe: Recipe
    private let stack = DataController.shared
    @State private var showShareSheet = false

    
//    @State var users: [User] = []
//    @State private var emailAddress: String = ""
    @State private var householdState: HouseholdState = .notLoggedIn
    enum HouseholdState {
        case loggedIn
        case notLoggedIn
//        case addMember
        case inviteSent
    }
    var dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: -15){
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .onTapGesture {
                    dismissAction()
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
                
                switch householdState{
                    
//MARK: -- // NOT LOGGED IN //
                case .notLoggedIn:
                    Text("Please sign in to\n create a household.")
                        .font(.system(size: 20))
                        .multilineTextAlignment(.center)
                    Button("  Sign in with Apple            ") {
                        withAnimation {
//                            users.append(User(userType: .member))
                            
                            let user = User(context: moc)
                            user.id = UUID()
                            user.userType = UserType.member.rawValue
                            try? moc.save()
                            
                            householdState = .loggedIn
                        }
                    }
                    .font(.system(size: 20))
                    .padding()
                    .background(Color.black)
                    .cornerRadius(30)
                    .foregroundColor(.white)
                    
//MARK: -- // LOGGED IN //
                case .loggedIn:
                    HStack(spacing: 10){
                        ForEach(householdMembers) { member in
                            VStack(spacing: 5){
                                ZStack{
                                    Circle()
                                        .padding([.leading, .trailing])
//                                    Text(user.state.image)
                                    Text(image(for: member.role))
                                        .font(.system(size: 45))
                                    Button(action: {
//                                        let user = users.last!
//                                        moc.delete(user)
                                        
                                        withAnimation {
//                                            try? moc.save()
                                            if householdMembers.isEmpty{
                                                householdState = .notLoggedIn
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
//                                Text(user.state.text)
                                
                                if member.role == .owner{
                                    let title = member.userIdentity.nameComponents?.givenName ?? "You"
                                    Text(title)
                                } else if member.acceptanceStatus == .accepted{
                                    let title = member.userIdentity.nameComponents?.givenName ?? "Fam #1"
                                    Text(title)
                                } else if member.acceptanceStatus == .pending{
//                                    Text(string(for: user.permission))
                                    Text("Invite sent")
                                }
                            }
                        }
                        
                        if householdMembers.count < 3{
                            VStack(spacing: 5){
                                Button(action: {
//                                    withAnimation {
                                    Task {
                                        self.share = try await createShare()
                                    }
                                        showShareSheet = true
//------------------OPEN QUESTION: USE STATE-BASED ANIMATIONS OR SHOW SHARE SHEET-------------------
//                                       householdState = .addMember
//                                       }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 75, height: 75)
                                        .foregroundColor(.gray)
                                }
                                Text("Add a member")
                            }
                        }
                        
                        Spacer()
                    }.frame(height: 100)
                    
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
                    
                    
//MARK: -- // INVITE SENT //
                case .inviteSent:
                    Text("Invitation sent! 🎉")
                        .font(.system(size: 30, weight: .medium))
                        .multilineTextAlignment(.center)
                        .padding(50)
                }
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
            } else{
//                showWarningOnlyHouseholdOwnersCanAddNewMembers()
            }
        })
        .onAppear(){
            Task{
                self.householdMembers = await getParticipants()
            }
            
//            self.share = stack.getShare(recipe)
            if !householdMembers.isEmpty{
                householdState = .loggedIn
            }
        }
    }
    
    func handleInviteSent(){
        withAnimation {
            householdState = .inviteSent
        }
//        users.append(User(userType: .pending))
        
        let user = User(context: moc)
        user.id = UUID()
        user.userType = UserType.pending.rawValue
        try? moc.save()
    }
}

//struct Household_Previews: PreviewProvider {
//    static var previews: some View {
//        Household(dismissAction: {})
//    }
//}

// MARK: -- Returns CKShare participant permission, methods and properties to share

extension Household {
//    SHARES INDIVIDUAL OBJECTS. E.G. RECIPES. NOT ENTIRE ZONE. BUT IT WORKS.
//    private func createShare(_ recipe: Recipe) async {
//        do {
//            let (_, share, _) = try await stack.persistentContainer.share([recipe], to: nil)
//            share[CKShare.SystemFieldKey.title] = recipe.title
//            self.share = share
//        } catch {
//            print("Failed to create share")
//        }
//    }
    
    func createShare() async throws -> CKShare {
        let allZones = try await stack.ckContainer.privateCloudDatabase.allRecordZones()
        guard let recipeZone = allZones.first(where: { $0.zoneID.zoneName == "com.apple.coredata.cloudkit.zone" }) else {
            fatalError("no recipe zone exists in cloudkit.")
        }
        
//        let lookIntoThis = CKRecordNameZoneWideShare use this to re-do the check for existing share. also use a static zone to make creation of share easier
        
        if recipeZone.capabilities.contains(.zoneWideSharing),
           let shareList = try? stack.persistentContainer.fetchShares(in: stack.privatePersistentStore),
           let existingShare = shareList.first,
              existingShare.recordID.recordName == CKRecordNameZoneWideShare{
            return existingShare
            
        } else{
            _ = try await stack.ckContainer.privateCloudDatabase.modifyRecordZones(
                saving: [CKRecordZone(zoneName: recipeZone.zoneID.zoneName)],
                deleting: [] )
            
            let share = CKShare(recordZoneID: recipeZone.zoneID)
            share.publicPermission = .readOnly
            let result = try await stack.ckContainer.privateCloudDatabase.save(share)
            return result as! CKShare
        }
    }
    
    func getParticipants() async -> [CKShare.Participant]{
        let allZones = try? await stack.ckContainer.privateCloudDatabase.allRecordZones()
        guard let recipeZone = allZones?.first(where: { $0.zoneID.zoneName == "com.apple.coredata.cloudkit.zone" }) else {
            fatalError("no recipe zone exists in cloudkit.")
        }
        
        if recipeZone.capabilities.contains(.zoneWideSharing),
           let shareList = try? stack.persistentContainer.fetchShares(in: stack.privatePersistentStore),
           let existingShare = shareList.first{
            let participants = existingShare.participants
            return participants
        }
        return []
    }
    
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
//    func string(for acceptanceStatus: CKShare.ParticipantAcceptanceStatus) -> String {
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
    
//    private var canEdit: Bool {
//        stack.canEdit(object: recipe)
//    }
}

extension CKShare.Participant: Identifiable{}
