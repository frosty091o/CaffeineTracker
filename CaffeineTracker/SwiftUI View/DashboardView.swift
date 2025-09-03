//
//  Untitled.swift
//  CaffeineTracker
//
//  Created by Ethan on 4/9/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var manager: CaffeineIntakeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Caffeine Summary Card
                VStack(spacing: 10) {
                    Text("\(Int(manager.todaysTotalCaffeine()))")
                        .font(.system(size: 60, weight: .bold))
                    
                    Text("mg of caffeine today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Progress Bar
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(height: 20)
                            .foregroundColor(.gray.opacity(0.3))
                            .cornerRadius(10)
                        
                        Rectangle()
                            .frame(width: CGFloat(manager.percentageOfLimit()) * 300, height: 20)
                            .foregroundColor(manager.isOverLimit() ? .red : .green)
                            .cornerRadius(10)
                    }
                    .frame(width: 300)
                    
                    Text("\(Int(manager.percentageOfLimit() * 100))% of daily limit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                
                // Today's Entries List
                if manager.todaysEntries().isEmpty {
                    Text("No caffeine logged today")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Today's Drinks")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(manager.todaysEntries()) { entry in
                                HStack {
                                    Image(systemName: entry.beverageType.category.iconName)
                                        .foregroundColor(.blue)
                                    
                                    Text(entry.beverageType.name)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(entry.caffeineAmount)) mg")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 5)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Add Button
                Button(action: {
                    let entry = CaffeineEntry(
                        beverageType: .espresso,
                        caffeineAmount: 63
                    )
                    manager.addEntry(entry)
                }) {
                    Label("Add Espresso", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Caffeine Tracker")
        }
    }
}
