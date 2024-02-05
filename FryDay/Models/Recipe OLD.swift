//
//  Recipe.swift
//  FryDay
//
//  Created by Theo Goodman on 1/31/23.
//

import Foundation
import CoreData

//struct Recipe: Hashable, Codable, Identifiable {
//    var id = UUID()
//
//    var recipeId: Int
//    var title: String
//    var imageUrl: String = ""
//    var source: String = ""
//    var ingredients: Array<Int> = []
//    var websiteUrl: String = ""
//    var cooktime: String? = nil
//    var recipeStatusId: Int = 1
//
////    var url: URL = URL(string: "https://www.cnn.com")!
//}

public class Recipe: NSManagedObject, Codable {
    
    private enum CodingKeys: String, CodingKey {
       case recipeId = "recipeId",
            title = "title",
            imageUrl = "imageUrl",
            source = "source",
            ingredients = "ingredients",
            categories = "categories",
            websiteUrl = "websiteUrl",
            cooktime = "cooktime",
            recipeStatusId = "recipeStatusId"
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
              throw DecoderConfigurationError.missingManagedObjectContext
            }
        
        self.init(context: context)
        
        id = UUID()
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else { fatalError() }
        recipeId = try! container.decode(Int64.self, forKey: .recipeId)
        title = try! container.decode(String.self, forKey: .title)
        imageUrl = try! container.decode(String.self, forKey: .imageUrl)
        websiteUrl = try! container.decode(String.self, forKey: .websiteUrl)
        source = try! container.decode(String.self, forKey: .source)
        cooktime = try! container.decodeIfPresent(String.self, forKey: .cooktime)
        recipeStatusId = try! container.decode(Int16.self, forKey: .recipeStatusId)
        
        let ingredientsList = try! container.decode(String.self, forKey: .ingredients)
        let newRecipeIngredientsList = (ingredientsList.split(separator: ";"))
        let recipeIngredientsArray = newRecipeIngredientsList.map{ Int($0)! }
        ingredients = recipeIngredientsArray
        
        let categoriesList = try! container.decode(String.self, forKey: .categories)
        let newRecipeCategoriesList = (categoriesList.split(separator: ";"))
        let recipeCategoriesArray = newRecipeCategoriesList.map{ Int($0)! }
        categories = recipeCategoriesArray
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try! container.encode(recipeId.self, forKey: .recipeId)
        try! container.encode(title.self, forKey: .title)
        try! container.encode(imageUrl.self, forKey: .imageUrl)
        try! container.encode(websiteUrl.self, forKey: .websiteUrl)
        try! container.encode(source.self, forKey: .source)
        try! container.encodeIfPresent(cooktime.self, forKey: .cooktime)
        try! container.encode(recipeStatusId.self, forKey: .recipeStatusId)
        try! container.encode(ingredients.self, forKey: .ingredients)
        try! container.encode(categories.self, forKey: .categories)
      }
}

extension CodingUserInfoKey {
  static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}

enum DecoderConfigurationError: Error {
  case missingManagedObjectContext
}




//MARK: -- RECIPE DETAILS

struct RecipeDetails: Hashable, Codable {
    var facts: [Fact]
    var ingredients: [Ingredient]
    var steps: [Step]
}

struct Fact: Hashable, Codable {
    var recipeId: Int = 0
    var factType: Int = 0
    var factText: String = ""
}

struct Ingredient: Hashable, Codable {
    var recipeId: Int = 0
    var ingredientText: String = ""
}

struct Step: Hashable, Codable {
    var recipeId: Int = 0
    var stepNumber: Int = 0
    var stepText: String = ""
}


// adopted from the tutorial @ https://www.kodeco.com/29934862-sharing-core-data-with-cloudkit-in-swiftui

//// MARK: Fetch request and managed object properties
//extension Recipe {
//  @nonobjc
//  public class func fetchRequest() -> NSFetchRequest<Recipe> {
//    return NSFetchRequest<Recipe>(entityName: "Recipe")
//  }
//
//}

//// MARK: Identifiable
//extension Recipe: Identifiable {
//}
