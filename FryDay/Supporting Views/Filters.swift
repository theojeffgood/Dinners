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
    
    //    @State private var products: [Product] = []
    //    var filterApplied: (Category?) -> Void
    //    var dismissAction: () -> Void
    
    @Binding var appliedFilters: [Category]
    @State private var groupedCategories: [String: [Category]] = [:] /* ["Filter Type": [Filters of the type]] */
    @State private var filterWasApplied = false
    
    var body: some View {
        NavigationStack{
            List{
                let groups = Array(groupedCategories.keys)
                ForEach(groups, id: \.self){ group in
//                    ForEach(groupedCategories, id: \.self) { key, value in
                    Section{
                        let categoryGroup: [Category]? = groupedCategories[group]
                        let products:   [Product]      = purchaseManager.getProductsForCategories(categoryGroup)
                        
                        ForEach(products, id: \.self){ product in
                            HStack{
                                Text(product.displayName)
                                Spacer()
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(product)
                                            self.filterWasApplied = true
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Text(verbatim: product.displayPrice)
                                        .padding(8.5)
                                        .foregroundStyle(.blue)
                                        .background(.gray.opacity(0.3))
                                        .clipShape(.capsule)
                                        .padding(1.0)
                                }
                            }
                        }
                    }
                    
                header: {
                    Text(verbatim: group)
                        .headerProminence(.increased)
                }
                footer: {
                    if group == groups.last{
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
            }.listStyle(.grouped)
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.large)
                .onAppear(perform: {
                    let categories = Category.allCategories(in: moc)
                    groupCategoriesByType(categories)
                    
                    _ = Task<Void, Never> {
                        do {
                            try! await purchaseManager.loadAppStoreProducts(for: categories)
                            //                        self.products = purchaseManager.products
                        } catch {
                            print(error)
                        }
                    }
                })
                .onDisappear(perform: {
                    let purchases = purchaseManager.purchasedProductIDs
                    let filters = purchasedCategoriesFor(purchases)
                    self.appliedFilters = filters
                })
        }
    }
}

#Preview {
    Filters(appliedFilters: .constant([]))
}

extension Filters{
    
    func groupCategoriesByType(_ categories: [Category]){
        for category in categories {
            if var categoryGroup = groupedCategories[category.group]{
                categoryGroup.append(category)
                groupedCategories[category.group] = categoryGroup
            } else{
                groupedCategories[category.group] = [category]
            }
        }
    }
    
    func purchasedCategoriesFor(_ productIds: Set<String>) -> [Category]{
        let categories = Category.allCategories(in: moc)
        let purchasedProducts = categories.filter({ productIds.contains($0.appStoreProductId) })
        return purchasedProducts
    }
}

//struct ProductsList: View {
//    
//    @State var categories: [Category]
//    @State var products: [Product]
//    @State var purchase: (Product) async throws -> Void
//    @State var title: String
//    
//    init(categories: [Category], products: [Product], purchase: @escaping (Product) async throws -> Void, title: String) {
//        self.categories = categories
//        self.products = products.filter({ categories.map({ $0.title }).contains( $0.displayName ) })
//        self.purchase = purchase
//        self.title = title
//    }
//    
//    var body: some View{
//        Section{
////            let diets = [Category(title: "Vegetarian", id: 1), Category(title: "Vegan", id: 2), Category(title: "Gluten Free", id: 3)]
//            ForEach(products, id: \.self){ filter in
//                HStack{
//                    Text(filter.displayName)
//                    Spacer()
//                    Button {
//                        _ = Task<Void, Never> {
//                            do {
//                                try? await self.purchase(filter)
////                                try await purchaseManager.purchase(filter)
////                                self.filterWasApplied = true
//                            } catch {
//                                print(error)
//                            }
//                        }
//                    } label: {
//                        Text(verbatim: filter.displayPrice)
//                            .padding(8.5)
//                            .foregroundStyle(.blue)
//                            .background(.gray.opacity(0.3))
//                            .clipShape(.capsule)
//                            .padding(1.0)
//                    }
//                }
//            }
//        } header: {
//            Text(verbatim: title)
//                .headerProminence(.increased)
//        }
//    }
//}
