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
                        .monospacedDigit()
                        .foregroundColor(manager.isOverLimit() ? .red : .primary)
                    
                    Text("mg of caffeine today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Gauge(value: min(manager.percentageOfLimit(), 1), in: 0...1) {
                        EmptyView()
                    } currentValueLabel: {
                        Text("\(Int(manager.percentageOfLimit() * 100))%")
                            .font(.caption)
                            .monospacedDigit()
                    }
                    .gaugeStyle(.linearCapacity)
                    .tint(manager.isOverLimit() ? .red : .green)
                    .padding(.horizontal)
                    
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
                        EmptyView()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .frame(maxWidth: .infinity)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
                .padding(.top, 20)
                
                // Today's Entries List
                if manager.todaysEntries().isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 44))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No caffeine logged today")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Tap Add Drink to log your first beverage.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                } else {
                    List {
                        Section {
                            ForEach(manager.todaysEntries()) { entry in
                                HStack {
                                    Image(systemName: entry.beverageType.category.iconName)
                                        .foregroundColor(.blue)
                                        .frame(width: 30)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.beverageType.name)
                                            .font(.system(size: 16, weight: .medium))
                                        Text(entry.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("\(Int(entry.caffeineAmount)) mg")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, y: 1)
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        manager.deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                let todaysEntries = manager.todaysEntries()
                                for index in indexSet { manager.deleteEntry(todaysEntries[index]) }
                            }
                        } header: {
                            HStack {
                                Text("Today's Drinks")
                                    .font(.headline)
                                Spacer()
                                Text("\(manager.todaysEntries().count) items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .textCase(nil)
                            .padding(.bottom, 4)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Caffeine Tracker").font(.title2).bold()
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView()
                    .environmentObject(manager)
                    .onDisappear {
                        checkDailyLimit()
                    }
            }
            .padding(.horizontal, 20)
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    showingAddEntry = true
                }) {
                    Label("Add Drink", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manager.isOverLimit() ? Color.orange : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(radius: 2)
                }
                .padding(.horizontal)
                .padding(.bottom, 18)
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
