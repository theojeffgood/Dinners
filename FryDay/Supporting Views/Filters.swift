//
//  Filters.swift
//  FryDay
//
//  Created by Theo Goodman on 11/30/23.
//

import SwiftUI
import StoreKit

struct Filters: View {
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    @Binding var allCategories: [Category]
    @State private var categoryList: [String: [Category]] = [:] /* ["Filter Type": [Filters of the type]] */
//    @State private var filterWasApplied = false
    
    var body: some View {
        NavigationView{ /* Use NavView. Not NavStack. Hack to show large title. */
            List{
                let sortedCategoryList = categoryList.sorted(by: { $0.key < $1.key })
                ForEach(sortedCategoryList, id: \.key){ categoryTitle, categories in
                    Section{
                        ForEach(categories, id: \.self){ category in
                            HStack{
                                Text(category.appStoreProduct?.displayName ?? "")
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
                                                        category.isPurchased = true
                                                        try! moc.save()
                                                        
                                                    case .pending, .userCancelled:
                                                        handlePurchaseFail()
                                                    @unknown default:
                                                        handlePurchaseFail()
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
                header: {
                    Text(verbatim: categoryTitle)
                }
//                footer: {
//                    let isLastSection = (categoryTitle == sortedCategoryList.last?.key)
//                    if isLastSection{
//                        HStack{
//                            Text("Want to see a new filter?")
//                                .font(.subheadline)
//                            Button {
//                                print("penis")
//                            } label: {
//                                Text("Let us know!")
//                                    .foregroundStyle(.blue)
//                                    .font(.subheadline)
//                            }
//                        }
//                    }
//                }
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
                
                _ = Task<Void, Never> {
                    do {
                        print("### Starting call to load appStoreProducts for: \(allCategories.count) categories")
                        try await purchaseManager.loadAppStoreProducts(for: allCategories)
                    } catch {
                        print(error)
                    }
                }
            }
//            .onDisappear {
//                let purchasedProductIds = purchaseManager.purchasedProductIDs
//                for productId in purchasedProductIds{
//                    guard let category = appliedFilters.first(where: { $0.appStoreProductId == productId }) else { continue }
//                    appliedFilters.removeAll(where: { $0 == category })
//                    category.isPurchased = false
//                }
////                appliedFilters.removeAll(where: { !purchasedProductIds.contains($0.appStoreProductId) })
//            }
        }
    }
}

//#Preview {
//    Filters()
//}

extension Filters{
    func handlePurchaseFail(){
    }
}
