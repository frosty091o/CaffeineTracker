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
            
            Button("Add Espresso") {
                let entry = CaffeineEntry(
                    beverageType: .espresso,
                    caffeineAmount: 63
                )
                manager.addEntry(entry)
            }
            
            Text("Entries: \(manager.entries.count)")
        }
        .padding()
    }
}
#Preview {
    ContentView()
}
