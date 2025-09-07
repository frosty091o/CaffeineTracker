//
//  CaffeineLookupService.swift
//  CaffeineTracker
//
//  Created by Ethan on 7/9/2025.
//

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
    func fetchByBarcodeOFF(barcode: String) async throws -> [LookupResult] {
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

        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            return []
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)

        guard decoded.status == 1, let p = decoded.product else { return [] }
        let mg = p.nutriments?.caffeine_serving ?? p.nutriments?.caffeine_100g
        let name = p.product_name ?? "Unknown product"
        return [LookupResult(displayName: name, mgPerServing: mg)]
    }

    // MARK: - Open Food Facts (name search)
    func searchOFFByName(name: String) async throws -> [LookupResult] {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }

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

        var comps = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        comps.queryItems = [
            URLQueryItem(name: "search_terms", value: name),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "10")
        ]

        guard let url = comps.url else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(OFFSearchResponse.self, from: data)

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
    func searchFDC(name: String) async throws -> [LookupResult] {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }

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

        var comps = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        comps.queryItems = [
            URLQueryItem(name: "query", value: name),
            URLQueryItem(name: "pageSize", value: "10"),
            URLQueryItem(name: "dataType", value: "SR Legacy,FNDDS,Survey (FNDDS),Branded"),
            URLQueryItem(name: "api_key", value: fdcKey)
        ]

        guard let url = comps.url else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(FDCSearch.self, from: data)

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
