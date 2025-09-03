//  ContentView.swift
//  CaffeineTracker
//
//  Created by Ethan on 23/8/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = CaffeineIntakeManager()
    
    var body: some View {
        DashboardView()
            .environmentObject(manager)
    }
}

#Preview {
    ContentView()
}
