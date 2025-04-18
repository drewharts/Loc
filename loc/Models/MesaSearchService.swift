import Foundation
import SwiftUI
import FirebaseFirestore

struct MesaSuggestion: Codable {
    let address: String
    let id: String
    let location: Location
    let name: String
    let source: String
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
    }
}

struct MesaSearchResponse: Codable {
    let suggestions: [MesaSuggestion]
}

class MesaSearchService {
    private let baseURL = "https://mesa-backend-production.up.railway.app"
    private var searchResults: [MesaSuggestion] = []  // Cache for search results
    
    func searchPlaces(query: String, limit: Int = 5, completion: @escaping ([MesaSuggestion], Error?) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/suggestions?query=\(encodedQuery)&limit=\(limit)&provider=all") else {
            completion([], NSError(domain: "MesaSearch", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid query"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion([], error)
                return
            }
            
            guard let data = data else {
                completion([], NSError(domain: "MesaSearch", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(MesaSearchResponse.self, from: data)
                self?.searchResults = response.suggestions  // Cache the results
                completion(response.suggestions, nil)
            } catch {
                completion([], error)
            }
        }
        
        task.resume()
    }
    
    func getPlaceDetails(id: String, completion: @escaping (Result<DetailPlace, Error>) -> Void) {
        // For now, we'll create a DetailPlace directly from the suggestion
        // This will be updated once you provide the details endpoint
        guard let suggestion = searchResults.first(where: { $0.id == id }) else {
            completion(.failure(NSError(domain: "MesaSearch", code: -1, userInfo: [NSLocalizedDescriptionKey: "Suggestion not found"])))
            return
        }
        
        let detailPlace = DetailPlace(from: suggestion)
        completion(.success(detailPlace))
    }
} 