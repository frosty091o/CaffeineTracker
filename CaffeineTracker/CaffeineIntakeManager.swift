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
    
    init() {
        print("Good")
    }
    
    //
    func addEntry(_ entry: CaffeineEntry) {
        entries.append(entry)
        print("Added entry: \(entry.beverageType.name)")
    }
    
    func deleteEntry(_ entry: CaffeineEntry) {
        entries.removeAll { $0.id == entry.id }
    }
    
    func todaysTotalCaffeine() -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        // Filter to only today's entries
        let todaysEntries = entries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: today)
        }
        
        // Add up all caffeine amounts
        let total = todaysEntries.reduce(0) { sum, entry in
            sum + entry.caffeineAmount
        }
        
        return total
    }
}
