//
//  CaffeineIntakeManager.swift
//  CaffeineTracker
//
//  Created by Ethan on 23/8/2025.
//

import Foundation
import SwiftUI

class CaffeineIntakeManager: ObservableObject {
    @Published var entries: [CaffeineEntry] = []
    @Published var dailyLimit: Double = 400.0
    
    private let entriesKey = "caffeineEntries"
    
    init() {
        loadEntries()
    }
    
    func addEntry(_ entry: CaffeineEntry) {
        entries.append(entry)
        saveEntries()
    }
    
    func deleteEntry(_ entry: CaffeineEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func todaysTotalCaffeine() -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        let todaysEntries = entries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: today)
        }
        
        let total = todaysEntries.reduce(0) { sum, entry in
            sum + entry.caffeineAmount
        }
        
        return total
    }
    
    // MARK: - Persistence
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let decoded = try? JSONDecoder().decode([CaffeineEntry].self, from: data) else {
            return
        }
        entries = decoded
    }
    
    func todaysEntries() -> [CaffeineEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        return entries
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func isOverLimit() -> Bool {
        return todaysTotalCaffeine() > dailyLimit
    }

    func percentageOfLimit() -> Double {
        let percentage = todaysTotalCaffeine() / dailyLimit
        return min(percentage, 1.5)
    }

    func entriesCount() -> Int {
        return entries.count
    }

    func clearAllEntries() {
        entries.removeAll()
        saveEntries()
    }
}
