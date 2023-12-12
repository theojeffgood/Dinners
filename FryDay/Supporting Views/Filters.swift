//
//  Filters.swift
//  FryDay
//
//  Created by Theo Goodman on 11/30/23.
//

import SwiftUI
import StoreKit

struct Filters: View {
    
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var products: [Product] = []
    @State private var filterWasApplied = false
    @Binding var appliedFilters: [Category]
//    var filterApplied: (Category?) -> Void
    var dismissAction: () -> Void
    
    var body: some View {
        NavigationStack{
                List{
                    Section{
//                        let diets = ["Vegetarian", "Vegan", "Gluten Free"]
                        let diets = [Category(title: "Vegetarian", id: 1), Category(title: "Vegan", id: 2), Category(title: "Gluten Free", id: 3)]
                        ForEach(products.filter({ diets.map({ $0.title }).contains($0.displayName) }), id: \.self){ filter in
                            HStack{
                                Text(filter.displayName)
                                Spacer()
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(filter)
                                            self.filterWasApplied = true
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Text("$0.99")
                                        .padding(8.5)
                                        .foregroundStyle(.blue)
                                        .background(.gray.opacity(0.3))
                                        .clipShape(.capsule)
                                        .padding(1.0)
                                }
                            }
                        }
                    } header: {
                        Text("Diets")
                            .headerProminence(.increased)
                    }
                    Section{
//                        let keyIngredients = ["Chicken", "Ground Beef", "Pasta", "Tofu & Tempeh", "Legumes", "Fish", "Sausage"]
                        let keyIngredients = [Category(title: "Chicken", id: 4), Category(title: "Ground Beef", id: 5), Category(title: "Pasta", id: 6), Category(title: "Tofu & Tempeh", id: 7), Category(title: "Legumes", id: 8), Category(title: "Fish", id: 9), Category(title: "Sausage", id: 10)]
                        ForEach(products.filter({ keyIngredients.map({ $0.title }).contains($0.displayName) }), id: \.self){ filter in
                            HStack{
                                Text(filter.displayName)
                                Spacer()
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(filter)
                                            self.filterWasApplied = true
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Text("$0.99")
                                        .padding(8.5)
                                        .foregroundStyle(.blue)
                                        .background(.gray.opacity(0.3))
                                        .clipShape(.capsule)
                                        .padding(1.0)
                                }
                            }
                        }
                    } header: {
                        Text("Key Ingredients")
                            .headerProminence(.increased)
                    }
                    Section{
//                        let cuisines = ["Asian", "French", "Italian", "Mediterranean", "Mexican", "Middle Eastern"]
                        let cuisines = [Category(title: "Asian", id: 11), Category(title: "French", id: 12), Category(title: "Italian", id: 13), Category(title: "Mediterranean", id: 14), Category(title: "Mexican", id: 15), Category(title: "Middle Eastern", id: 16)]
                        ForEach(products.filter({ cuisines.map({ $0.title }).contains($0.displayName) }), id: \.self){ filter in
                            HStack{
                                Text(filter.displayName)
                                Spacer()
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(filter)
                                            self.filterWasApplied = true
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Text("$0.99")
                                        .padding(8.5)
                                        .foregroundStyle(.blue)
                                        .background(.gray.opacity(0.3))
                                        .clipShape(.capsule)
                                        .padding(1.0)
                                }
                            }
                        }
                    } header: {
                        Text("Cuisines")
                            .headerProminence(.increased)
                    }
                    Section{
//                        let mealTypes = ["Dinner", "Breakfast", "One Pot", "<30 min"]
                        let mealTypes = [Category(title: "Dinner", id: 17), Category(title: "Breakfast", id: 18), Category(title: "One Pot", id: 19), Category(title: "<30 min", id: 20)]
                        ForEach(products.filter({ mealTypes.map({ $0.title }).contains($0.displayName) }), id: \.self){ filter in
                            HStack{
                                Text(filter.displayName)
                                Spacer()
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(filter)
                                            self.filterWasApplied = true
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Text("$0.99")
                                        .padding(8.5)
                                        .foregroundStyle(.blue)
                                        .background(.gray.opacity(0.3))
                                        .clipShape(.capsule)
                                        .padding(1.0)
                                }
                            }
                        }
                    } header: {
                        Text("Meal Type")
                            .headerProminence(.increased)
                    }
                footer: {
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
                }.listStyle(.grouped)
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.large)
                .onDisappear(perform: {
                    if filterWasApplied{
                        let filters = self.products.filter({ purchaseManager.purchasedProductIDs.contains($0.id) })
                        var appliedFilters: [Category] = []
                        for i in 0...filters.count - 1{
                            let filter = filters[i]
                            appliedFilters.append(Category(title: filter.displayName, id: i))
                        }
                        self.appliedFilters = appliedFilters
                    }
                })
        }.task {
            _ = Task<Void, Never> {
                do {
                    try await purchaseManager.loadProducts()
                    self.products = purchaseManager.products
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    Filters(appliedFilters: .constant([]), dismissAction: {})
}

//let filterTypes: [String:String] = [
//    "Vegetarian": "Diets",
//    "Vegan": "Diets",
//    "Gluten Free": "Diets",
//    "Chicken": "Key Ingredients",
//    "Ground Beef": "Key Ingredients",
//    "Pasta": "Key Ingredients",
//    "Tofu & Tempeh": "Key Ingredients",
//    "Legumes": "Key Ingredients",
//    "Fish": "Key Ingredients",
//    "Sausage": "Key Ingredients",
//    "Asian": "Cuisines",
//    "French": "Cuisines",
//    "Italian": "Cuisines",
//    "Mediterranean": "Cuisines",
//    "Mexican": "Cuisines",
//    "Middle Eastern": "Cuisines",
//    "Dinner": "Meal Types",
//    "Breakfast": "Meal Types",
//    "One Pot": "Meal Types",
//    "<30 min": "Meal Types",
//]

struct Category: Identifiable {
    var title: String
    var id: Int
}
