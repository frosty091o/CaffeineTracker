//
//  CalendarView.swift
//  CaffeineTracker
//
//  Created by Ethan on 7/9/2025.
//

// calendar screen: pick a day, see quick stats, and dive into details.

import SwiftUI

struct CalendarView: View {
    // data + UI state
    // selectedDate drives the grid highlight and the quick stats at the bottom
    @EnvironmentObject var manager: CaffeineIntakeManager
    @State private var selectedDate = Date()
    @State private var showingDateDetail = false
    @State private var showingAddEntry = false
    
    // use the user’s current calendar/locale
    let calendar = Calendar.current
    
    // first day of the visible month (used for headers + padding calc)
    var month: Date {
        calendar.dateInterval(of: .month, for: selectedDate)?.start ?? Date()
    }
    
    // all days in the visible month as Date values
    var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let daysInMonth = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day else {
            return []
        }
        
        // build an array by adding 0..days-1 to the month start
        return (0..<daysInMonth).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: monthInterval.start)
        }
    }
    
    // title like “September 2025”
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // month nav + title
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(monthYearString)
                        .font(.title2.weight(.semibold))
                    Spacer()
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) { Divider() }
                
                // SUN..SAT header row (localized short labels)
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day.uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // calendar grid (7 columns). nils are empty pads before/after the month
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                    ForEach(daysWithPadding(), id: \.self) { date in
                        // draw a real day cell or a transparent spacer
                        if let date = date {
                            DayView(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                                .environmentObject(manager)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                        selectedDate = date
                                    }
                                    showingDateDetail = true
                                }
                        } else {
                            Color.clear
                                .frame(height: 50)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // quick stats for the selected day
                VStack(spacing: 10) {
                    Text(formatSelectedDate())
                        .font(.headline)
                    
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                            Text("\(Int(manager.totalCaffeine(for: selectedDate))) mg")
                                .monospacedDigit()
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Divider().frame(height: 28)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "cup.and.saucer.fill")
                            Text("\(manager.entries(for: selectedDate).count) drinks")
                                .monospacedDigit()
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Divider().frame(height: 28)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "percent")
                            Text("\(Int(manager.percentageOfLimit(for: selectedDate) * 100))% of limit")
                                .monospacedDigit()
                                .font(.headline)
                                .foregroundColor(manager.isOverLimit(for: selectedDate) ? .red : .green)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Calendar")
                        .font(.title2)
                        .bold()
                }
                // jump back to today
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
    
    // build a 7×N grid: leading/trailing nils pad the first/last week
    func daysWithPadding() -> [Date?] {
        var days: [Date?] = []
        
        // how many blanks before the 1st of the month (0-based index)
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
    
    // go to previous month
    func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    // go to next month
    func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
    
    // friendly label for the selected day (Today/Yesterday/Date)
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
    
    // “1”, “2”, ... for the cell label
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    // true only for the real current day
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // per-day data from the manager
    var caffeineAmount: Double {
        manager.totalCaffeine(for: date)
    }
    
    var hasEntries: Bool {
        manager.hasEntries(for: date)
    }
    
    var body: some View {
        ZStack {
            // fill the whole cell when it’s today (no tiny dot)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isToday ? Color.accentColor.opacity(0.12) : Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1)
            
            VStack(spacing: 6) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(.primary)
                
                // show mg badge or a dash if empty
                if hasEntries {
                    Text("\(Int(caffeineAmount))")
                        .font(.system(size: 10, weight: .semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundColor(manager.isOverLimit(for: date) ? .red : .green)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill((manager.isOverLimit(for: date) ? Color.red.opacity(0.12) : Color.green.opacity(0.12)))
                        )
                } else {
                    Text("—")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
        }
        .frame(width: 44, height: 56)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                // selected date outline
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isSelected)
    }
}

// Date Detail View
struct DateDetailView: View {
    let date: Date
    @EnvironmentObject var manager: CaffeineIntakeManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAddEntry = false
    
    // big title for the detail sheet
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    // entries for this day (drives the list)
    var entries: [CaffeineEntry] {
        manager.entries(for: date)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // summary card: total mg + progress to daily limit
                VStack(spacing: 10) {
                    Text("\(Int(manager.totalCaffeine(for: date)))")
                        .font(.system(size: 50, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(manager.isOverLimit(for: date) ? .red : .primary)
                    
                    Text("mg of caffeine")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: min(manager.percentageOfLimit(for: date), 1.0))
                        .tint(manager.isOverLimit(for: date) ? .red : .green)
                        .padding(.horizontal)
                        .opacity(0.9)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
                .padding()
                
                // empty state vs. list of entries
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
                            // entry row
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
                            // simple delete (no undo)
                            for index in indexSet {
                                manager.deleteEntry(entries[index])
                            }
                        }
                    }
                }
                
                // quick add button scoped to this date
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
