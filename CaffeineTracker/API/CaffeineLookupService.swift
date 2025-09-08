//
//  CaffeineLookupService.swift
//  CaffeineTracker
//
//  Created by Ethan on 7/9/2025.
//

// Service to fetch caffeine content from OpenFoodFacts and USDA

import Foundation

struct LookupResult: Identifiable, Hashable {
    let id = UUID()
    let displayName: String
    let mgPerServing: Double?
}

final class CaffeineLookupService {
    private let fdcKey: String
    init(fdcKey: String) { self.fdcKey = fdcKey }

    // MARK: - Open Food Facts (barcode)
    /// Fetch caffeine info by scanning a barcode from OpenFoodFacts.
    func fetchByBarcodeOFF(barcode: String) async throws -> [LookupResult] {
        // Define the response structure matching the JSON we expect from OFF
        struct OFFResponse: Decodable {
            struct Product: Decodable {
                struct Nutriments: Decodable {
                    let caffeine_100g: Double?
                    let caffeine_serving: Double?
                }
                let product_name: String?
                let nutriments: Nutriments?
            }
            let status: Int
            let product: Product?
        }

        // Build the URL for the barcode lookup
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            return []
        }
        // Fetch data from the API
        let (data, _) = try await URLSession.shared.data(from: url)
        // Decode the JSON into our structs
        let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)

        // Check if product exists and extract caffeine info
        guard decoded.status == 1, let p = decoded.product else { return [] }
        let mg = p.nutriments?.caffeine_serving ?? p.nutriments?.caffeine_100g
        let name = p.product_name ?? "Unknown product"
        // Return a single result with the product name and caffeine amount
        return [LookupResult(displayName: name, mgPerServing: mg)]
    }

    // MARK: - Open Food Facts (name search)
    /// Search for products by name on OpenFoodFacts and get caffeine content.
    func searchOFFByName(name: String) async throws -> [LookupResult] {
        // Ignore empty or whitespace-only search terms
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }

        // Define the response structure for search results
        struct OFFSearchResponse: Decodable {
            struct P: Decodable {
                struct Nutriments: Decodable {
                    let caffeine_serving: Double?
                    let caffeine_100g: Double?
                }
                let product_name: String?
                let nutriments: Nutriments?
            }
            let products: [P]
        }

        // Build the search URL with query parameters
        var comps = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        comps.queryItems = [
            URLQueryItem(name: "search_terms", value: name),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "10")
        ]

        guard let url = comps.url else { return [] }
        // Fetch search results from the API
        let (data, _) = try await URLSession.shared.data(from: url)
        // Decode the JSON response
        let decoded = try JSONDecoder().decode(OFFSearchResponse.self, from: data)

        // Map each product to a LookupResult if it has caffeine info > 0
        return decoded.products.compactMap { p in
            let mg = p.nutriments?.caffeine_serving ?? p.nutriments?.caffeine_100g
            if let mg = mg, mg > 0 {
                return LookupResult(displayName: p.product_name ?? "Unnamed product", mgPerServing: mg)
            } else {
                return nil
            }
        }
    }

    // MARK: - USDA FoodData Central (generic foods/drinks)
    /// Search USDA FoodData Central for generic foods and their caffeine content.
    func searchFDC(name: String) async throws -> [LookupResult] {
        // Skip empty search terms
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }

        // Define the expected JSON response structure
        struct FDCSearch: Decodable {
            struct Food: Decodable {
                struct Nutrient: Decodable {
                    let nutrientId: Int
                    let unitName: String
                    let value: Double
                }
                let description: String
                let foodNutrients: [Nutrient]
            }
            let foods: [Food]
        }

        // Build the URL with query parameters for the USDA API
        var comps = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        comps.queryItems = [
            URLQueryItem(name: "query", value: name),
            URLQueryItem(name: "pageSize", value: "10"),
            URLQueryItem(name: "dataType", value: "SR Legacy,FNDDS,Survey (FNDDS),Branded"),
            URLQueryItem(name: "api_key", value: fdcKey)
        ]

        guard let url = comps.url else { return [] }
        // Fetch search results from USDA
        let (data, _) = try await URLSession.shared.data(from: url)
        // Decode the JSON response
        let decoded = try JSONDecoder().decode(FDCSearch.self, from: data)

        // Extract caffeine nutrient (id 1057) and filter out results without caffeine
        return decoded.foods.map { food -> LookupResult in
            let caf = food.foodNutrients.first { $0.nutrientId == 1057 }
            return LookupResult(displayName: food.description, mgPerServing: caf?.value)
        }.filter { result in
            if let mg = result.mgPerServing, mg > 0 {
                return true
            }
            return false
        }
    }
}
