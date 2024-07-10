//
//  FiltersBar.swift
//  FryDay
//
//  Created by Theo Goodman on 4/3/24.
//

import SwiftUI

struct FiltersBar: View {
    @Binding var filterIsActive: Bool
    @Binding var showFilters: Bool
    @Binding var items: Set<Category>
    var buttonPressed: (Category) -> Void
    
    init(filterIsActive: Binding<Bool>, showFilters: Binding<Bool>, items: Binding<Set<Category>>, buttonPressed: @escaping (Category) -> Void) {
        self._filterIsActive = filterIsActive
        self._showFilters = showFilters
        self._items = items
        self.buttonPressed = buttonPressed
    }
    
    var body: some View{
        HStack{
            Button{
                withAnimation { showFilters = true }
            } label: {
                Label("filters", systemImage: "slider.horizontal.3")
            }
            .buttonStyle( FilterButtonStyle() )
            
            if !items.isEmpty{
                ScrollView(.horizontal){
                    HStack {
                        let sortedItems = items.sorted(by: { $0.id > $1.id })
                        ForEach(sortedItems){ item in
                            Button {
                                withAnimation{
                                    buttonPressed(item)
                                }
                            } label: {
                                let textColor: Color       = filterIsActive ? .white : .black
                                let backgroundColor: Color = filterIsActive ? .black : .white
                                
                                Text(item.title + (filterIsActive ? "  X" : ""))
                                    .font(.custom("Solway-Light", size: 16))
                                    .frame(height: 42)
                                    .padding(.horizontal)
                                    .foregroundStyle(textColor)
                                    .background(backgroundColor)
                                    .cornerRadius(20, corners: .allCorners)
                                    .overlay( RoundedRectangle(cornerRadius: 20).stroke(Color.init(hex: 0xE8EAEA), lineWidth: 1) )
                                    .padding([.top, .bottom], 1)
                            }
                        }
                    }.padding(.leading, 1)
                }.scrollIndicators(.never)
            }
            Spacer()
        }
    }
}

#Preview {
    FiltersBar(filterIsActive: .constant(true),
               showFilters: .constant(false),
               items: .constant(Set()),
               buttonPressed: { _ in })
}

