//
//  SettingsView.swift
//  CaffeineTracker
//
//  Created by Ethan on 6/9/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: CaffeineIntakeManager
    @State private var dailyLimitText = ""
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Daily Limit Section
                Section(header: Text("Daily Limit")) {
                    HStack {
                        Text("Caffeine Limit")
                        Spacer()
                        TextField("400", text: $dailyLimitText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onAppear {
                                dailyLimitText = String(Int(manager.dailyLimit))
                            }
                            .onChange(of: dailyLimitText) { newValue in
                                if let limit = Double(newValue), limit > 0 {
                                    manager.dailyLimit = limit
                                    manager.saveDailyLimit()
                                }
                            }
                        Text("mg")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Recommended daily limit is 400mg for adults")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Statistics Section
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Total Entries")
                        Spacer()
                        Text("\(manager.entries.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Today's Entries")
                        Spacer()
                        Text("\(manager.todaysEntries().count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Today's Total")
                        Spacer()
                        Text("\(Int(manager.todaysTotalCaffeine())) mg")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Data Management Section
                Section(header: Text("Data Management")) {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Text("Clear All Data")
                            .foregroundColor(.red)
                    }
                }
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    manager.clearAllEntries()
                }
            } message: {
                Text("This will permanently delete all your caffeine entries. This cannot be undone.")
            }
        }
    }
}
