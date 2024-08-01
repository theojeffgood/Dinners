//
//  RecipesList.swift
//  FryDay
//
//  Created by Theo Goodman on 1/18/23.
//

import SwiftUI
import CloudKit

struct RecipesList: View {
    
    @ObservedObject var recipeManager: RecipeManager
//    @FetchRequest(fetchRequest: Vote.allVotes) var allVotes
    @State private var showTabbar: Bool = true
    @State private var isMenuOpen: Bool = false

    var body: some View {
        NavigationStack{
            VStack{
                Picker("", selection: $recipeManager.recipeType) {
                    ForEach(RecipeType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 10)
                
                if !recipeManager.recipes.isEmpty{
                    ScrollView{
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 0),
                                            GridItem(.flexible())]) {
                            ForEach(recipeManager.recipes, id: \.self) { recipe in
                                
                                ZStack(alignment: .topTrailing){
                                    NavigationLink { RecipeDetailsView(recipe: recipe,
                                                                       recipeTitle: recipe.title!)
                                    .onAppear { withAnimation { showTabbar = false } }
                                    } label: { RecipeCell(recipe: recipe) }
                                    
                                    Menu {
                                        Button("Unlike this recipe", action: { withAnimation{ unlikeRecipe(recipe) } } )
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .resizable()
                                            .frame(width: 22, height: 22)
                                            .padding([.top, .trailing], 15)
                                            .colorInvert()
                                    }
                                    .onTapGesture { isMenuOpen = true }
                                }
                            }
                        }
                    }
                    .overlay{
                        if isMenuOpen {
                            Color.white.opacity(0.001)
                                .ignoresSafeArea()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .gesture( DragGesture().onEnded({ _ in isMenuOpen = false }))
                                .gesture(  TapGesture().onEnded({ _ in isMenuOpen = false }))
                        }
                    }
                } else{ EmptyState(for: $recipeManager.recipeType) }
            }.navigationTitle("Matches")
                .onAppear{
                    showTabbar = true
                    recipeManager.recipeType = recipeManager.recipeType /* refreshes data */
                }
        }.toolbar(showTabbar ? .visible : .hidden, for: .tabBar)
    }
    
    func unlikeRecipe(_ recipe: Recipe){
        recipeManager.deleteVote(for: recipe)
        isMenuOpen = false
    }
}

struct RecipeCell: View {
    var recipe: Recipe
//    @State private var isPressed: Bool = false
    
    var body: some View {
        VStack(alignment: .center){
            GeometryReader { geo in
                    AsyncImage(url: URL(string: recipe.imageUrl!)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                            
                        } else { ProgressView() }
                    }
                    .frame(width: geo.size.width, height: 200)
                    .clipped() // prevents taps outside clipped image frame
                    .allowsHitTesting(false) // prevents taps outside clipped image frame
            }
            
            Text(recipe.title!)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity,
                       maxHeight: 100,
                       alignment: .leading)
                .background(.white)
                .font(.custom("Solway-Light", size: 18))
                .foregroundColor(.black)
        }
        .frame(height: 290)
        .cornerRadius(10, corners: .allCorners)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.clear)
        )
        .shadow(radius: 10)

//        .scaleEffect(isPressed ? 0.95 : 1.0)
//        .animation(.easeInOut(duration: 0.1), value: isPressed)
//        .onTapGesture {
//            isPressed = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                isPressed = false
//            }
//        }
    }
}

struct EmptyState: View {
    @Binding var recipeType: RecipeType
    
    init(for recipeType: Binding<RecipeType>) {
        self._recipeType = recipeType
    }
    
    var body: some View {
        switch recipeType {
            
        case .likes:
            VStack(spacing: 20, content: {
                Spacer()
                Image(systemName: "heart.slash")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 100, maxHeight: 100)
                    .foregroundColor(.gray.opacity(0.6))
                
                let message = recipeType.emptyState
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.custom("Solway-Light", size: 30))
                Spacer()
            })
            
        case .matches:
            VStack(spacing: -90, content: {
                Spacer()
                let message = recipeType.emptyState
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.custom("Solway-Light", size: 30))
                Spacer()
                Image(.pointerArrow)
                    .resizable()
                    .frame(maxHeight: 350)
                    .offset(x: 40, y: 25)
            })
        }
    }
}

enum RecipeType: String, CaseIterable {
    case matches = "Matches"
    case likes   = "My Likes"
    
    var emptyState: String{
        switch self {
        case .matches:
            return "No matches, yet. \n\n Add people to your household."
        case .likes:
            return "No likes, yet. \n\n Start liking recipes."
        }
    }
}

import CoreData

struct RecipesList_Previews: PreviewProvider {
    static let entity = NSManagedObjectModel
        .mergedModel(from: nil)?
        .entitiesByName["Recipe"]
    
    static var previews: some View {
        let recipeOne = Recipe(entity: entity!, insertInto: nil)
        recipeOne.title = "Chicken Parm"
        recipeOne.imageUrl = "https://halflemons-media.s3.amazonaws.com/786.jpg"
        
        let recipeTwo = Recipe(entity: entity!, insertInto: nil)
        recipeTwo.title = "Split Pea Soup"
        recipeTwo.imageUrl = "https://halflemons-media.s3.amazonaws.com/785.jpg"
        
        let recipeThree = Recipe(entity: entity!, insertInto: nil)
        recipeThree.title = "BBQ Ribs"
        recipeThree.imageUrl = "https://halflemons-media.s3.amazonaws.com/784.jpg"
        
        let moc = DataController.shared.context
        let recipeManager = RecipeManager(managedObjectContext: moc)
        
        //        return RecipesList(recipesType: "Matches", recipes: [])
//        return RecipesList(recipeManager: recipeManager, recipesType: "Matches", recipes: [recipeOne, recipeTwo, recipeThree])
        return RecipesList(recipeManager: recipeManager)
    }
}
