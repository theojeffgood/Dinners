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
    @State var products: [Product] = []
    
    var dismissAction: () -> Void
    
    var body: some View {
        NavigationStack{
                List{
                    Section{
                        let diets = ["Vegetarian", "Vegan", "Gluten Free"]
                        ForEach(products.filter({ diets.contains($0.displayName) }), id: \.self){ filter in
                            HStack{
                                Text(filter.displayName)
                                Spacer()
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(filter)
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
                        let keyIngredients = ["Chicken", "Ground Beef", "Pasta", "Tofu & Tempeh", "Legumes", "Fish", "Sausage"]
                        ForEach(products.filter({ keyIngredients.contains($0.displayName) }), id: \.self){ filter in
                            HStack{
                                Text(filter.displayName)
                                Spacer()
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(filter)
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
                        let cuisines = ["Asian","French", "Italian", "Mediterranean", "Mexican", "Middle Eastern"]
                        ForEach(products.filter({ cuisines.contains($0.displayName) }), id: \.self){ filter in
                            HStack{
                                Text(filter.displayName)
                                Spacer()
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(filter)
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
                        let mealTypes = ["Dinner", "Breakfast", "One Pot", "<30 min"]
                        ForEach(products.filter({ mealTypes.contains($0.displayName) }), id: \.self){ filter in
                            HStack{
                                Text(filter.displayName)
                                Spacer()
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(filter)
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
    Filters(dismissAction: {})
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
