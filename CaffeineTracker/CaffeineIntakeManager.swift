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
    
    /// Average daily intake over the last `days` days.
    /// By default this averages only days with entries (more representative of actual consumption days).
    /// If you prefer to include zero-intake days, change the divisor to `Double(days)`.
    func averageDailyIntake(days: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var sum: Double = 0
        var daysWithEntries = 0

        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dailyTotal = self.totalCaffeine(for: date)
            if dailyTotal > 0 {
                sum += dailyTotal
                daysWithEntries += 1
            }
        }

        return daysWithEntries > 0 ? sum / Double(daysWithEntries) : 0
    }

    /// Convenience: map a UI period to an average.
    func dailyAverage(period: String = "Week") -> Double {
        let days: Int
        switch period {
        case "Week": days = 7
        case "Month": days = 30
        default: days = 365
        }
        return averageDailyIntake(days: days)
    }

    /// Count total drinks in the last `days` days.
    func totalDrinks(inLast days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.timestamp > cutoff }.count
    }

    /// Convenience: map a UI period to total drinks.
    func totalDrinks(period: String = "Week") -> Int {
        let days: Int
        switch period {
        case "Week": days = 7
        case "Month": days = 30
        default: days = 365
        }
        return totalDrinks(inLast: days)
    }

    /// Number of days over the limit in the last `days` days.
    func daysOverLimit(inLast days: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var count = 0
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                if totalCaffeine(for: date) > dailyLimit { count += 1 }
            }
        }
        return count
    }

    /// Convenience: map a UI period to days over limit.
    func daysOverLimit(period: String = "Week") -> Int {
        let days: Int
        switch period {
        case "Week": days = 7
        case "Month": days = 30
        default: days = 365
        }
        return daysOverLimit(inLast: days)
    }

    /// Current streak (consecutive days) at or under the daily limit, ending today.
    func currentStreak() -> Int {
        var streak = 0
        var date = Date()
        let calendar = Calendar.current
        while totalCaffeine(for: date) <= dailyLimit {
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDate
            if !hasEntries(for: date) { break }
        }
        return max(0, streak - 1)
    }

    /// Helper: entries from the last `days` days (newest first)
    func entriesInLastDays(_ days: Int) -> [CaffeineEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.timestamp >= cutoff }.sorted { $0.timestamp > $1.timestamp }
    }

    /// Helper: total per-day for the last `days` days, oldest → newest
    func lastNDaysTotals(_ days: Int) -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [(Date, Double)] = []
        for i in stride(from: days - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            result.append((date, totalCaffeine(for: date)))
        }
        return result
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
