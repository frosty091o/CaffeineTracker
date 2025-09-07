//
//  Untitled.swift
//  CaffeineTracker
//
//  Created by Ethan on 4/9/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var manager: CaffeineIntakeManager
    @State private var showingAddEntry = false
    @State private var showingLimitAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Caffeine Summary Card
                VStack(spacing: 10) {
                    Text("\(Int(manager.todaysTotalCaffeine()))")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(manager.isOverLimit() ? .red : .primary)
                    
                    Text("mg of caffeine today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Progress Bar - Fixed so doesnt overflow
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(height: 20)
                            .foregroundColor(.gray.opacity(0.3))
                            .cornerRadius(10)
                        
                        Rectangle()
                            .frame(width: min(CGFloat(manager.percentageOfLimit()) * 300, 300), height: 20)
                            .foregroundColor(manager.isOverLimit() ? .red : .green)
                            .cornerRadius(10)
                            .animation(.easeInOut(duration: 0.3), value: manager.percentageOfLimit())
                    }
                    .frame(width: 300)
                    
                    // Percentage text with warning
                    if manager.isOverLimit() {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("\(Int(manager.percentageOfLimit() * 100))% - OVER LIMIT")
                                .font(.caption)
                                .foregroundColor(.red)
                                .bold()
                        }
                    } else {
                        Text("\(Int(manager.percentageOfLimit() * 100))% of daily limit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                
                // Today's Entries List
                if manager.todaysEntries().isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No caffeine logged today")
                            .foregroundColor(.secondary)
                        Text("Tap the button below to add your first drink")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Today's Drinks")
                                    .font(.headline)
                                Spacer()
                                Text("\(manager.todaysEntries().count) items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            ForEach(manager.todaysEntries()) { entry in
                                HStack {
                                    Image(systemName: entry.beverageType.category.iconName)
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text(entry.beverageType.name)
                                            .font(.system(size: 16, weight: .medium))
                                        Text(entry.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(Int(entry.caffeineAmount)) mg")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        if let notes = entry.notes, !notes.isEmpty {
                                            Image(systemName: "note.text")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .padding(.horizontal, 10)
                            }
                            .onDelete { indexSet in
                                let todaysEntries = manager.todaysEntries()
                                for index in indexSet {
                                    manager.deleteEntry(todaysEntries[index])
                                }
                            }
                        }
                    }
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(10)
                    .padding(.horizontal, 5)
                }
                
                Spacer()
                
                // Remaining caffeine indicator
                if !manager.isOverLimit() && manager.todaysEntries().count > 0 {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("You can have \(Int(manager.remainingCaffeine())) mg more today")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Add Button
                Button(action: {
                    showingAddEntry = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Drink")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(manager.isOverLimit() ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Caffeine Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddEntry = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView()
                    .environmentObject(manager)
                    .onDisappear {
                        checkDailyLimit()
                    }
            }
        }
        .onAppear {
            checkDailyLimit()
        }
        .alert("Daily Limit Exceeded", isPresented: $showingLimitAlert) {
            Button("OK") { }
        } message: {
            Text("You've exceeded your daily caffeine limit of \(Int(manager.dailyLimit))mg. Consider reducing intake.")
        }
    }
    
    func checkDailyLimit() {
        if manager.isOverLimit() && !manager.todaysEntries().isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingLimitAlert = true
            }
        }
    }
}
