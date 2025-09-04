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
    
    var calculatedCaffeine: Double {
        if useCustomAmount {
            return Double(customAmount) ?? selectedBeverage.defaultCaffeineContent
        }
        return selectedBeverage.defaultCaffeineContent
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
                    } else {
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text("\(Int(selectedBeverage.defaultCaffeineContent)) mg")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Preview
                Section(header: Text("Preview")) {
                    HStack {
                        Image(systemName: selectedBeverage.category.iconName)
                            .foregroundColor(.blue)
                        Text(selectedBeverage.name)
                        Spacer()
                        Text("\(Int(calculatedCaffeine)) mg")
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
                        let entry = CaffeineEntry(
                            beverageType: selectedBeverage,
                            caffeineAmount: calculatedCaffeine
                        )
                        manager.addEntry(entry)
                        dismiss()
                    }
                }
            }
        }
    }
}
