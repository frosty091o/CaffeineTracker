//
//  AddEntryForDateView.swift
//  CaffeineTracker
//
//  Created by Ethan on 7/9/2025.
/// Form for adding a caffeine entry on a specific calendar date.
/// Lets the user pick the beverage, set time on that day, and optionally enter a custom amount.

import SwiftUI

struct AddEntryForDateView: View {
    // Injected manager for saving entries and reading settings
    // Dismiss action provided by SwiftUI to close the sheet
    let targetDate: Date
    @EnvironmentObject var manager: CaffeineIntakeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedBeverage = BeverageType.espresso
    @State private var customAmount = ""
    @State private var useCustomAmount = false
    @State private var notes = ""
    @State private var selectedTime = Date()
    
    /// Computes the caffeine value to save. Uses custom input when toggled on.
    var calculatedCaffeine: Double {
        if useCustomAmount {
            return Double(customAmount) ?? 0
        }
        return selectedBeverage.defaultCaffeineContent
    }
    
    var body: some View {
        NavigationView {
            // Main form broken into small sections for clarity
            Form {
                // Pick the time for the entry; date label reminds which day we're editing
                Section(header: Text("Date & Time")) {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    
                    Text("Date: \(targetDate, style: .date)")
                        .foregroundColor(.secondary)
                }
                
                // Choose from preset beverages (amount comes from the preset unless custom is enabled)
                Section(header: Text("Select Beverage")) {
                    Picker("Beverage", selection: $selectedBeverage) {
                        ForEach(BeverageType.allPresets, id: \.name) { beverage in
                            Text(beverage.name).tag(beverage)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Toggle custom amount to type your own mg value
                Section(header: Text("Caffeine Content")) {
                    Toggle("Custom Amount", isOn: $useCustomAmount)
                    
                    if useCustomAmount {
                        TextField("Caffeine (mg)", text: $customAmount)
                            .keyboardType(.numberPad)
                    } else {
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text("\(Int(selectedBeverage.defaultCaffeineContent)) mg")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Optional notes saved on the entry (e.g., brand, size, etc.)
                Section(header: Text("Notes (Optional)")) {
                    TextField("Add notes...", text: $notes)
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Close without saving
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                // Validate and save the entry
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addEntry()
                    }
                    .disabled(calculatedCaffeine <= 0)
                }
            }
        }
        // When the view opens, align the initial time to "now" but on the chosen target date
        .onAppear {
            // Set initial time to current time but on the target date
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: Date())
            selectedTime = calendar.date(bySettingHour: timeComponents.hour ?? 12,
                                       minute: timeComponents.minute ?? 0,
                                       second: 0,
                                       of: targetDate) ?? targetDate
        }
    }
    
    func addEntry() {
        // Merge the chosen day with the selected hour/minute to get a single Date
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        let combinedDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                        minute: timeComponents.minute ?? 0,
                                        second: 0,
                                        of: targetDate) ?? targetDate
        
        // Build the entry model from the current form state
        let entry = CaffeineEntry(
            timestamp: combinedDate,
            beverageType: selectedBeverage,
            caffeineAmount: calculatedCaffeine,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Save and close
        manager.addEntry(entry)
        dismiss()
    }
}
