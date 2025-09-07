//
//  AddEntryForDateView.swift
//  CaffeineTracker
//
//  Created by Ethan on 7/9/2025.
//

import SwiftUI

struct AddEntryForDateView: View {
    let targetDate: Date
    @EnvironmentObject var manager: CaffeineIntakeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedBeverage = BeverageType.espresso
    @State private var customAmount = ""
    @State private var useCustomAmount = false
    @State private var notes = ""
    @State private var selectedTime = Date()
    
    var calculatedCaffeine: Double {
        if useCustomAmount {
            return Double(customAmount) ?? 0
        }
        return selectedBeverage.defaultCaffeineContent
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date & Time")) {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    
                    Text("Date: \(targetDate, style: .date)")
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Select Beverage")) {
                    Picker("Beverage", selection: $selectedBeverage) {
                        ForEach(BeverageType.allPresets, id: \.name) { beverage in
                            Text(beverage.name).tag(beverage)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
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
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("Add notes...", text: $notes)
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addEntry()
                    }
                    .disabled(calculatedCaffeine <= 0)
                }
            }
        }
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
        // Combine target date with selected time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        let combinedDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                        minute: timeComponents.minute ?? 0,
                                        second: 0,
                                        of: targetDate) ?? targetDate
        
        let entry = CaffeineEntry(
            timestamp: combinedDate,
            beverageType: selectedBeverage,
            caffeineAmount: calculatedCaffeine,
            notes: notes.isEmpty ? nil : notes
        )
        
        manager.addEntry(entry)
        dismiss()
    }
}
