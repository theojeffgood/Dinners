//
//  WebService.swift
//  FryDay
//
//  Created by Theo Goodman on 1/22/23.
//

import Foundation
import CoreData

class Webservice {
    var moc: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.moc = context
    }
    
    func load<T: Codable>(_ resource: Resource<T>) async throws -> T {
        
        var request = URLRequest(url: resource.url)
//        request.addValue ("application/json", forHTTPHeaderField: "Content-Type") -- is this needed? tweet says no.
        request.allHTTPHeaderFields = resource.headers
        
        switch resource.method {
        case .post(let data):
            request.httpMethod = resource.method.name
            request.httpBody = data
            
        case .get (let queryItems):
            var components = URLComponents (url: resource.url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            guard let url = components?.url else {
                throw NetworkError.badUrl
            }
            request = URLRequest(url: url)
            print("request: \(request)")
        }
        
        // create the URLSession configuration
        let configuration = URLSessionConfiguration.default
        // add default headers
        configuration.httpAdditionalHeaders = ["Content-Type": "application/json"]
        let session = URLSession (configuration: configuration)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw NetworkError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = moc

            let result = try decoder.decode(T.self, from: data)
            return result
            
        } catch let error{
            if let decodingError = error as? DecodingError{
                print("decodingError is: \(decodingError)")
            }
            fatalError("Failed to decode data of type: \(T.self)")
        }
        
    }
}

//MARK: --

enum NetworkError: Error {
    case invalidResponse
    case badUrl
    case decodingError
}

extension URL {
    static func forRecipeById(_ id: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "appdata.halflemons.com"
        components.path = "/recipedetails/\(id)"
        return components.url
    }
    
    static var allRecipes: URL {
        URL(string: "https://appdata.halflemons.com/recipes")!
    }
}

//MARK: --

extension Recipe {
    static var all: Resource<[Recipe]>{
        return Resource(url: URL.allRecipes)
    }
    
    
}

extension RecipeDetails {
    static func byId(_ id: Int) -> Resource<RecipeDetails> {
        guard let url = URL.forRecipeById(id) else {
            fatalError("id = \(id) was not found.")
        }
        return Resource(url: url)
    }
}

enum HttpMethod {
    case get ([URLQueryItem])
    case post (Data?)
    var name: String {
        
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        }
    }
}

struct Resource<T: Codable> {
    let url: URL
    var headers: [String: String] = ["Content-Type": "application/json"]
    var method: HttpMethod = .get([])
}
