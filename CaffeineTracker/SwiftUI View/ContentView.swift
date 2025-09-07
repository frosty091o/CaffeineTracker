//  ContentView.swift
//  CaffeineTracker
//
//  Created by Ethan on 23/8/2025.
//

import SwiftUI

struct ContentView: View {
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
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
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
