//  ContentView.swift
//  CaffeineTracker
//
//  Created by Ethan on 23/8/2025.
//

import SwiftUI

// main entry view with a TabView for Today, Calendar, Stats, Settings
struct ContentView: View {
    // one manager instance shared across all tabs
    @StateObject private var manager = CaffeineIntakeManager()
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "cup.and.saucer.fill")
                }
                .environmentObject(manager)
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .environmentObject(manager)
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .environmentObject(manager)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .environmentObject(manager)
        }
    }
}
