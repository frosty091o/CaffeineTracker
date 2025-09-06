//
//  Models.swift
//  CaffeineTracker
//
//  Created by Ethan on 23/8/2025.
//

import Foundation

// MARK: - Protocols

protocol Trackable {
    var id: UUID { get }
    var timestamp: Date { get }
}

protocol Beverage {
    var name: String { get }
    var defaultCaffeineContent: Double { get }
    var servingSize: Double { get }
    var category: BeverageCategory { get }
}

protocol Persistable: Codable {
    static var storageKey: String { get }
}

// MARK: - Enums

enum BeverageCategory: String, CaseIterable, Codable {
    case coffee = "Coffee"
    case tea = "Tea"
    case energyDrink = "Energy Drink"
    case softDrink = "Soft Drink"
    
    var iconName: String {
        switch self {
        case .coffee:
            return "cup.and.saucer.fill"
        case .tea:
            return "leaf.fill"
        case .energyDrink:
            return "bolt.fill"
        case .softDrink:
            return "bubbles.and.sparkles.fill"
        }
    }
}

// MARK: - Models

struct BeverageType: Beverage, Codable, Hashable {
    let name: String
    let defaultCaffeineContent: Double
    let servingSize: Double
    let category: BeverageCategory
}

extension BeverageType {
    static let espresso = BeverageType(
        name: "Espresso",
        defaultCaffeineContent: 63,
        servingSize: 30,
        category: .coffee
    )
    
    static let americano = BeverageType(
        name: "Americano",
        defaultCaffeineContent: 94,
        servingSize: 240,
        category: .coffee
    )
    
    static let latte = BeverageType(
        name: "Latte",
        defaultCaffeineContent: 63,
        servingSize: 240,
        category: .coffee
    )
    
    static let cappuccino = BeverageType(
        name: "Cappuccino",
        defaultCaffeineContent: 75,
        servingSize: 180,
        category: .coffee
    )
    
    static let blackTea = BeverageType(
        name: "Black Tea",
        defaultCaffeineContent: 47,
        servingSize: 240,
        category: .tea
    )
    
    static let greenTea = BeverageType(
        name: "Green Tea",
        defaultCaffeineContent: 28,
        servingSize: 240,
        category: .tea
    )
    
    static let energyDrink = BeverageType(
        name: "Energy Drink",
        defaultCaffeineContent: 80,
        servingSize: 250,
        category: .energyDrink
    )
    
    static let cola = BeverageType(
        name: "Cola",
        defaultCaffeineContent: 32,
        servingSize: 355,
        category: .softDrink
    )
    
    static var allPresets: [BeverageType] {
        [espresso, americano, latte, cappuccino, blackTea, greenTea, energyDrink, cola]
    }
}

struct CaffeineEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let beverageType: BeverageType
    let caffeineAmount: Double
    let servingSize: Double
    let notes: String?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        beverageType: BeverageType,
        caffeineAmount: Double,
        servingSize: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.beverageType = beverageType
        self.caffeineAmount = caffeineAmount
        self.servingSize = servingSize ?? beverageType.servingSize
        self.notes = notes
    }
}

extension CaffeineEntry: Trackable {}

extension CaffeineEntry: Persistable {
    static var storageKey: String { "caffeineEntries" }
}

// MARK: - Error Handling

// Find this enum and add Equatable:
enum CaffeineTrackerError: LocalizedError, Equatable {
    case invalidAmount
    case exceedsMaximumLimit(limit: Double)
    case dataCorrupted
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid amount greater than 0"
        case .exceedsMaximumLimit(let limit):
            return "Warning: This exceeds the recommended daily limit of \(Int(limit))mg"
        case .dataCorrupted:
            return "Unable to load saved data"
        case .saveFailed:
            return "Failed to save your entry. Please try again."
        }
    }
}

// MARK: - Validation

extension CaffeineEntry {
    var isValid: Bool {
        caffeineAmount > 0 && caffeineAmount < 1000
    }
}

extension BeverageType {
    var isHighCaffeine: Bool {
        defaultCaffeineContent > 150
    }
    
    var caffeineLevel: String {
        switch defaultCaffeineContent {
        case 0..<50:
            return "Low"
        case 50..<150:
            return "Moderate"
        default:
            return "High"
        }
    }
}

// MARK: - Date Extensions

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
}
