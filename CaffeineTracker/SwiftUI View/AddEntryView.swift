//
//  AddEntryView.swift
//  CaffeineTracker
//
//  Created by Ethan on 3/9/2025.
//

import SwiftUI

struct AddEntryView: View {
    @EnvironmentObject var manager: CaffeineIntakeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedBeverage = BeverageType.espresso
    @State private var customAmount = ""
    @State private var useCustomAmount = false
    @State private var notes = ""
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var calculatedCaffeine: Double {
        if useCustomAmount {
            return Double(customAmount) ?? 0
        }
        return selectedBeverage.defaultCaffeineContent
    }
    
    var isValidEntry: Bool {
        calculatedCaffeine > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Beverage Selection
                Section(header: Text("Select Beverage")) {
                    Picker("Beverage", selection: $selectedBeverage) {
                        ForEach(BeverageType.allPresets, id: \.name) { beverage in
                            Text(beverage.name).tag(beverage)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Caffeine Amount
                Section(header: Text("Caffeine Content")) {
                    Toggle("Custom Amount", isOn: $useCustomAmount)
                    
                    if useCustomAmount {
                        TextField("Caffeine (mg)", text: $customAmount)
                            .keyboardType(.numberPad)
                        
                        if !customAmount.isEmpty && Double(customAmount) == nil {
                            Text("Please enter a valid number")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else {
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text("\(Int(selectedBeverage.defaultCaffeineContent)) mg")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Notes Section
                Section(header: Text("Notes (Optional)")) {
                    TextField("Add notes...", text: $notes)
                }
                
                // Warning Section
                if calculatedCaffeine > 200 {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("High caffeine content!")
                                .font(.caption)
                        }
                    }
                }
                
                if manager.todaysTotalCaffeine() + calculatedCaffeine > manager.dailyLimit {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("This will exceed your daily limit!")
                                .font(.caption)
                        }
                    }
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
                    .disabled(!isValidEntry)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    func addEntry() {
        // Validate amount
        guard calculatedCaffeine > 0 else {
            errorMessage = "Caffeine amount must be greater than 0"
            showingError = true
            return
        }
        
        guard calculatedCaffeine < 1000 else {
            errorMessage = "Caffeine amount seems too high. Please check."
            showingError = true
            return
        }
        
        // Create and add entry
        let entry = CaffeineEntry(
            beverageType: selectedBeverage,
            caffeineAmount: calculatedCaffeine,
            notes: notes.isEmpty ? nil : notes
        )
        
        manager.addEntry(entry)
        dismiss()
    }
}
