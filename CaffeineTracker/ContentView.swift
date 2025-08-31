//  ContentView.swift
//  CaffeineTracker
//
//  Created by Ethan on 23/8/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = CaffeineIntakeManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Total: \(manager.todaysTotalCaffeine(), specifier: "%.0f") mg")
            
            Text("Limit: \(manager.percentageOfLimit() * 100, specifier: "%.0f")%")
                .foregroundColor(manager.isOverLimit() ? .red : .green)
            
            Button("Add Espresso") {
                let entry = CaffeineEntry(
                    beverageType: .espresso,
                    caffeineAmount: 63
                )
                manager.addEntry(entry)
            }
            
            Text("Today's Entries: \(manager.todaysEntries().count)")
            Text("All Entries: \(manager.entriesCount())")
            
            if manager.entriesCount() > 0 {
                Button("Clear All") {
                    manager.clearAllEntries()
                }
                .foregroundColor(.red)
            }
        }
        .padding()
    }
}
#Preview {
    ContentView()
}
