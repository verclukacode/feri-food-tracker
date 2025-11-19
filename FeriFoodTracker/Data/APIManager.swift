//
//  APIManager.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 12. 11. 25.
//

import Foundation

enum USDAError: Error {
    case unknown
    case noAPIKey
}

class APIManager {
    
    private static var instance: APIManager?
    public static var shared: APIManager {
        if instance == nil {
            instance = APIManager()
        }
        return instance!
    }
    
    
    public static func getKey() -> String {
        let key1 = "RE".reversed()
        let key2 = "i".uppercased()
        return "F" + key1 + key2
    }
    
    
    public func searchFoods(prompt: String,
                            maxNumberOfResults: Int = 20,
                            completion: @escaping (Result<[FoodData], Error>) -> Void) {

        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

        var merged: [FoodData] = []

        // If prompt too short OR we already reached the cap, return early
        if trimmed.count < 4 || merged.count >= maxNumberOfResults {
            completion(.success(Array(merged.prefix(maxNumberOfResults))))
            return
        }

        // Build POST request to your endpoint
        guard let url = URL(string: "https://api.getyoa.app/yoaapi/usda/foods/search") else {
            completion(.success(Array(merged.prefix(maxNumberOfResults))))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "key": APIManager.getKey(),
            "query": trimmed,
            "pageSize": maxNumberOfResults
        ]

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            // If body encoding fails, just return local results
            completion(.success(Array(merged.prefix(maxNumberOfResults))))
            return
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let _ = error {
                // Network error — return whatever we have locally
                completion(.success(Array(merged.prefix(maxNumberOfResults))))
                return
            }

            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let data = data else {
                completion(.success(Array(merged.prefix(maxNumberOfResults))))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let root = json as? [String: Any],
                      let foodsArray = root["foods"] as? [[String: Any]] else {
                    // Unexpected shape — just return local
                    completion(.success(Array(merged.prefix(maxNumberOfResults))))
                    return
                }

                let remoteFoods = foodsArray.compactMap { FoodData(foodDict: $0) }
                merged.append(contentsOf: remoteFoods)
                #if canImport(FirebaseAnalytics)
                Analytics.logEvent("food_searched", parameters: ["prompt" : prompt])
                #endif
                completion(.success(Array(merged.prefix(maxNumberOfResults))))
            } catch {
                // Parse error — just return local
                completion(.success(Array(merged.prefix(maxNumberOfResults))))
            }
        }.resume()
    }
    
}
