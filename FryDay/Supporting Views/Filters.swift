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
    
    @Binding var appliedFilters: [Category]
    @State private var categoryList: [String: [Category]] = [:] /* ["Filter Type": [Filters of the type]] */
    @State private var filterWasApplied = false
    
    var body: some View {
        NavigationStack{
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
                                                    try await purchaseManager.purchase(product)
                                                    if !appliedFilters.contains(category){
                                                        appliedFilters.append(category)
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
                        .headerProminence(.increased)
                }
                footer: {
                    let isLastSection = (categoryTitle == sortedCategoryList.last?.key)
                    if isLastSection{
                        HStack{
                            Text("Want to see a new filter?")
                                .font(.subheadline)
                            Button {
                                print("penis")
                            } label: {
                                Text("Let us know!")
                                    .foregroundStyle(.blue)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.large)
            .onAppear{
                let categories = Category.allCategories(in: moc)
                groupCategoriesByType(categories)
                
                _ = Task<Void, Never> {
                    do {
                        try await purchaseManager.loadAppStoreProducts(for: categories)
                    } catch {
                        print(error)
                    }
                }
            }
            .onDisappear {
                let purchasedProductIds = purchaseManager.purchasedProductIDs
                appliedFilters.removeAll(where: { !purchasedProductIds.contains($0.appStoreProductId) })
            }
        }
    }
}

#Preview {
    Filters(appliedFilters: .constant([]))
}

extension Filters{
    
    func groupCategoriesByType(_ categories: [Category]){
        for category in categories {
            if var categoryGroup = categoryList[category.group]{
                categoryGroup.append(category)
                categoryList[category.group] = categoryGroup
            } else{
                categoryList[category.group] = [category]
            }
        }
    }
}

//struct ProductsSection: View {
//    
//    @State var categories: [Category]
//    @State var purchase: (Product) async throws -> Void
//    @State var categoryTitle: String
//    
//    init(categories: [Category], categoryTitle: String, purchase: @escaping (Product) async throws -> Void) {
//        self.categories = categories
//        self.purchase = purchase
//        self.categoryTitle = categoryTitle
//    }
//    
//    var body: some View{
//        Section{
//            ForEach(categories, id: \.self){ category in
//                HStack{
//                    Text(category.appStoreProduct?.displayName ?? "")
//                    Spacer()
//                    Button {
//                        _ = Task<Void, Never> {
//                            do {
////                                try await purchaseManager.purchase(category.appStoreProduct!)
//                                try await purchase(category.appStoreProduct!)
////                                appliedFilters.append(category)
//                            } catch {
//                                print(error)
//                            }
//                        }
//                    } label: {
//                        Text(verbatim: category.appStoreProduct?.displayPrice ?? "")
//                            .padding(8.5)
//                            .foregroundStyle(.blue)
//                            .background(.gray.opacity(0.3))
//                            .clipShape(.capsule)
//                            .padding(1.0)
//                    }
//                }
//            }
//        }
//    header: {
//        Text(verbatim: categoryTitle)
//            .headerProminence(.increased)
//    }
////    footer: {
////        let isLastSection = (categoryTitle == sortedCategoryList.last?.key)
////        if isLastSection{
////            HStack{
////                Text("Want to see a new filter?")
////                    .font(.subheadline)
////                Button {
////                    print("penis")
////                } label: {
////                    Text("Let us know!")
////                        .foregroundStyle(.blue)
////                        .font(.subheadline)
////                }
////            }
////        }
////    }
//    }
//}
