//
//  Filters.swift
//  FryDay
//
//  Created by Theo Goodman on 11/30/23.
//

import SwiftUI
import StoreKit
import OSLog

struct Filters: View {
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var purchaseManager: AppStoreManager
    
    @State var allCategories: [Category]
    @State private var categoryList: [String: [Category]] = [:] /* ["Filter Type": [Filters of the type]] */
    @State private var playConfetti = false
    @State private var purchaseFailed = false
    
    var body: some View {
        NavigationView{ /* Use NavView. Not NavStack. Hack to show large title. */
            ZStack{
                List{
                    let sortedCategoryList = categoryList.sorted(by: { $0.key < $1.key })
                    ForEach(sortedCategoryList, id: \.key){ categoryTitle, categories in
                        Section{
                            ForEach(categories, id: \.self){ category in
                                HStack{
                                    Text(category.appStoreProduct?.displayName ?? "")
                                        .font(.custom("Solway-Light", size: 16))
                                    Spacer()
                                    if purchaseManager.purchasedProductIDs.contains(category.appStoreProductId){
                                        Image(systemName: "checkmark.circle.fill")
                                            .resizable()
                                            .foregroundStyle(.green)
                                            .frame(width: 25, height: 25)
                                            .padding(.trailing)
                                    } else{
                                        Button {
                                            if let product = category.appStoreProduct{
                                                Task<Void, Never> {
                                                    do {
                                                        let result = try await purchaseManager.purchase(product)
                                                        switch result {
                                                        case .success:
                                                            playConfetti = true
                                                            purchase(category: category)
                                                            
                                                        case .pending, .userCancelled:
                                                            handlePurchaseFail()
                                                        @unknown default:
                                                            fatalError("Purchase failed for unknown reason.")
                                                        }
                                                    } catch {
                                                        print(error)
                                                    }
                                                }
                                            }
                                        } label: {
                                            Text(verbatim: category.appStoreProduct?.displayPrice ?? "")
                                                .padding(8.5)
                                                .foregroundStyle(.blue)
                                                .background(.gray.opacity(0.3))
                                                .clipShape(.capsule)
                                                .padding(1.0)
                                        }
                                    }
                                }
                            }
                        }
                    header: { Text(verbatim: categoryTitle).font(.custom("Solway-Bold", size: 18)) }
                    }
                }
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.large)
                .environment(\.defaultMinListRowHeight, 60)
                //            .listStyle(.grouped)
                .headerProminence(.increased)
                .onAppear{
                    for category in allCategories {
                        if var categoryGroup = categoryList[category.group]{
                            if categoryGroup.contains(category){ continue }
                            categoryGroup.append(category)
                            categoryList[category.group] = categoryGroup
                        } else{
                            categoryList[category.group] = [category]
                        }
                    }
                    
                    Task {
                        do {
                            Logger.store.info("Fetching appStoreProducts for: \(allCategories.count, privacy: .public) categories")
                            try await purchaseManager.loadAppStoreProducts(for: allCategories)
                            
                        } catch { Logger.store.error("Failed to get AppStore products: \(error, privacy: .public)") }
                    }
                }
                if playConfetti{
                    CelebrationView("Confetti", play: $playConfetti)
                        .id(1) // swiftui unique-ness thing
                        .allowsHitTesting(false)
                }
            }
        }
        .sheet(isPresented: $purchaseFailed) {
            PurchaseFailed()
        }
    }
}

#Preview {
    Filters(allCategories: [])
}

extension Filters{
    func purchase(category: Category){
        category.isPurchased = true
        let purchaseManager = PurchaseManager()
        let share = ShareCoordinator.shared.activeShare
        purchaseManager.createPurchase(for: category.id, share: share)
    }
    
    func handlePurchaseFail(){
        purchaseFailed.toggle()
    }
}
