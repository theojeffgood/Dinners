//
//  Filters.swift
//  FryDay
//
//  Created by Theo Goodman on 11/30/23.
//

import SwiftUI

struct Filters: View {
    var dismissAction: () -> Void
    
    var body: some View {
        NavigationStack{
                List{
                    Section{
                        let diets = ["Vegetarian", "Vegan", "Gluten Free"]
                        ForEach(diets, id: \.self){ filter in
                            HStack{
                                Text(filter)
                                Spacer()
                                Button {
                                    print("penis")
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
                        let keyIngredients = ["Chicken", "Ground Beef", "Pasta", "Tofu / Tempeh", "Legumes", "Fish", "Sausage"]
                        ForEach(keyIngredients, id: \.self){ filter in
                            HStack{
                                Text(filter)
                                Spacer()
                                Button {
                                    print("penis")
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
                        ForEach(cuisines, id: \.self){ filter in
                            HStack{
                                Text(filter)
                                Spacer()
                                Button {
                                    print("penis")
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
                        ForEach(mealTypes, id: \.self){ filter in
                            HStack{
                                Text(filter)
                                Spacer()
                                Button {
                                    print("penis")
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
        }
    }
}

#Preview {
    Filters(dismissAction: {})
}
