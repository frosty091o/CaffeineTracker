//
//  HistoryView.swift
//  CaffeineTracker
//
//  Created by Ethan on 3/9/2025.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var manager: CaffeineIntakeManager
    
    var groupedEntries: [Date: [CaffeineEntry]] {
        Dictionary(grouping: manager.entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
    }
    
    var sortedDays: [Date] {
        groupedEntries.keys.sorted(by: >)
    }
    
    func dayTotal(for date: Date) -> Double {
        let dayEntries = groupedEntries[date] ?? []
        return dayEntries.reduce(0) { $0 + $1.caffeineAmount }
    }
    
    func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if manager.entries.isEmpty {
                    Text("No entries yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sortedDays, id: \.self) { day in
                        Section(header: HStack {
                            Text(formatDate(day))
                            Spacer()
                            Text("\(Int(dayTotal(for: day))) mg")
                                .font(.caption)
                        }) {
                            ForEach(groupedEntries[day] ?? []) { entry in
                                HStack {
                                    Image(systemName: entry.beverageType.category.iconName)
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text(entry.beverageType.name)
                                        Text(entry.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(Int(entry.caffeineAmount)) mg")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onDelete { indexSet in
                                deleteEntries(for: day, at: indexSet)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
    
    func deleteEntries(for day: Date, at offsets: IndexSet) {
        let dayEntries = groupedEntries[day] ?? []
        for index in offsets {
            manager.deleteEntry(dayEntries[index])
        }
    }
}
