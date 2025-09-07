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
    private let dailyLimitKey = "dailyLimit"
    
    init() {
        // Load daily limit
        let savedLimit = UserDefaults.standard.double(forKey: dailyLimitKey)
        self.dailyLimit = savedLimit > 0 ? savedLimit : 400.0
        
        loadEntries()
    }
    
    // MARK: - CRUD Operations
    
    func addEntry(_ entry: CaffeineEntry) {
        entries.append(entry)
        saveEntries()
    }
    
    func deleteEntry(_ entry: CaffeineEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func updateEntry(_ entry: CaffeineEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }
    
    // MARK: - Query Methods
    
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
    
    func canAddMoreCaffeine() -> Bool {
        return todaysTotalCaffeine() < dailyLimit
    }
    
    func remainingCaffeine() -> Double {
        max(0, dailyLimit - todaysTotalCaffeine())
    }
    
    // MARK: - Validation
    
    func validateEntry(_ entry: CaffeineEntry) -> Result<CaffeineEntry, CaffeineTrackerError> {
        guard entry.caffeineAmount > 0 else {
            return .failure(.invalidAmount)
        }
        
        guard entry.caffeineAmount < 1000 else {
            return .failure(.exceedsMaximumLimit(limit: 1000))
        }
        
        return .success(entry)
    }
    
    // MARK: - Calendar Methods

    func entries(for date: Date) -> [CaffeineEntry] {
        let calendar = Calendar.current
        return entries
            .filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func totalCaffeine(for date: Date) -> Double {
        entries(for: date).reduce(0) { $0 + $1.caffeineAmount }
    }

    func isOverLimit(for date: Date) -> Bool {
        totalCaffeine(for: date) > dailyLimit
    }

    func percentageOfLimit(for date: Date) -> Double {
        let percentage = totalCaffeine(for: date) / dailyLimit
        return min(percentage, 1.5)
    }

    func hasEntries(for date: Date) -> Bool {
        !entries(for: date).isEmpty
    }
    
    // MARK: - Statistics
    
    func weeklyAverage() -> Double {
        let calendar = Calendar.current
        let today = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            return 0
        }
        
        let weekEntries = entries.filter { entry in
            entry.timestamp >= weekAgo && entry.timestamp <= today
        }
        
        let total = weekEntries.reduce(0) { $0 + $1.caffeineAmount }
        return total / 7.0
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
    
    func saveDailyLimit() {
        UserDefaults.standard.set(dailyLimit, forKey: dailyLimitKey)
    }
}
