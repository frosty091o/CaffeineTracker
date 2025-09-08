//
//  SettingsView.swift
//  CaffeineTracker
//
//  Created by Ethan on 6/9/2025.
//

// settings screen: edit daily limit, view stats, clear data, check app info

import SwiftUI

struct SettingsView: View {
    // shared data manager
    @EnvironmentObject var manager: CaffeineIntakeManager
    // text binding for caffeine limit field
    @State private var dailyLimitText = ""
    // flag for reset alert
    @State private var showingResetAlert = false
    
    var body: some View {
        // main container with nav + form
        NavigationView {
            Form {
                // daily limit
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
                
                // stats
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
                
                // data management
                Section(header: Text("Data Management")) {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Text("Clear All Data")
                            .foregroundColor(.red)
                    }
                }
                
                // about
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // centered title like other screens
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.title2)
                        .bold()
                }
            }
            // confirm before clearing all data
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
