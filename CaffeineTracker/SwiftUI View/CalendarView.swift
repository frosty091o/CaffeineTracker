//
//  CalendarView.swift
//  CaffeineTracker
//
//  Created by Ethan on 7/9/2025.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var manager: CaffeineIntakeManager
    @State private var selectedDate = Date()
    @State private var showingDateDetail = false
    @State private var showingAddEntry = false
    
    let calendar = Calendar.current
    
    var month: Date {
        calendar.dateInterval(of: .month, for: selectedDate)?.start ?? Date()
    }
    
    var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let daysInMonth = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day else {
            return []
        }
        
        return (0..<daysInMonth).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: monthInterval.start)
        }
    }
    
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Month Navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text(monthYearString)
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
                // Weekday Headers
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Calendar Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                    ForEach(daysWithPadding(), id: \.self) { date in
                        if let date = date {
                            DayView(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                                .environmentObject(manager)
                                .onTapGesture {
                                    selectedDate = date
                                    showingDateDetail = true
                                }
                        } else {
                            Color.clear
                                .frame(height: 50)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Quick Stats for Selected Date
                VStack(spacing: 10) {
                    Text(formatSelectedDate())
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(Int(manager.totalCaffeine(for: selectedDate)))")
                                .font(.title2)
                                .bold()
                            Text("mg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 30)
                        
                        VStack {
                            Text("\(manager.entries(for: selectedDate).count)")
                                .font(.title2)
                                .bold()
                            Text("drinks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 30)
                        
                        VStack {
                            Text("\(Int(manager.percentageOfLimit(for: selectedDate) * 100))%")
                                .font(.title2)
                                .bold()
                                .foregroundColor(manager.isOverLimit(for: selectedDate) ? .red : .green)
                            Text("of limit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        selectedDate = Date()
                    }
                }
            }
            .sheet(isPresented: $showingDateDetail) {
                DateDetailView(date: selectedDate)
                    .environmentObject(manager)
            }
        }
    }
    
    func daysWithPadding() -> [Date?] {
        var days: [Date?] = []
        
        // Add padding for days before month starts
        let firstWeekday = calendar.component(.weekday, from: month) - 1
        days.append(contentsOf: Array(repeating: nil, count: firstWeekday))
        
        // Add actual days
        days.append(contentsOf: monthDays.map { $0 })
        
        // Add padding to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
    
    func formatSelectedDate() -> String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: selectedDate)
        }
    }
}

// Day Cell View
struct DayView: View {
    let date: Date
    let isSelected: Bool
    @EnvironmentObject var manager: CaffeineIntakeManager
    
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var caffeineAmount: Double {
        manager.totalCaffeine(for: date)
    }
    
    var hasEntries: Bool {
        manager.hasEntries(for: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .white : .primary)
            
            if hasEntries {
                Text("\(Int(caffeineAmount))")
                    .font(.caption2)
                    .foregroundColor(manager.isOverLimit(for: date) ? .red : .green)
            } else {
                Text("-")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 40, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.accentColor : (isSelected ? Color(.systemGray5) : Color(.systemGray6)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// Date Detail View
struct DateDetailView: View {
    let date: Date
    @EnvironmentObject var manager: CaffeineIntakeManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAddEntry = false
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    var entries: [CaffeineEntry] {
        manager.entries(for: date)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Summary Card
                VStack(spacing: 10) {
                    Text("\(Int(manager.totalCaffeine(for: date)))")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(manager.isOverLimit(for: date) ? .red : .primary)
                    
                    Text("mg of caffeine")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: min(manager.percentageOfLimit(for: date), 1.0))
                        .tint(manager.isOverLimit(for: date) ? .red : .green)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding()
                
                // Entries List
                if entries.isEmpty {
                    VStack {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No entries for this day")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Spacer()
                } else {
                    List {
                        ForEach(entries) { entry in
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
                            for index in indexSet {
                                manager.deleteEntry(entries[index])
                            }
                        }
                    }
                }
                
                // Add Button
                Button(action: {
                    showingAddEntry = true
                }) {
                    Label("Add Entry for This Day", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryForDateView(targetDate: date)
                    .environmentObject(manager)
            }
        }
    }
}
