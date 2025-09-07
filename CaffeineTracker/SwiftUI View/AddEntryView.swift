//
//  AddEntryView.swift
//  CaffeineTracker
//
//  Created by Ethan on 3/9/2025.
//

import SwiftUI

struct AddEntryView: View {
    let lookup = CaffeineLookupService(fdcKey: "b0cehDATvB5rLhcsQTDDtO6GZia3fSeYjNzUAOBf")
    @EnvironmentObject var manager: CaffeineIntakeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedBeverage = BeverageType.espresso
    @State private var customAmount = ""
    @State private var useCustomAmount = false
    @State private var notes = ""
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var query = ""
    @State private var results: [LookupResult] = []
    @State private var isLoading = false
    
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
                
                // Lookup Section
                Section(header: Text("Lookup (Optional)")) {
                    TextField("Search by name or barcode", text: $query)
                    
                    Button("Search") {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            results = []
                            
                            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // If numeric -> treat as barcode (Open Food Facts first)
                            if !trimmed.isEmpty && trimmed.allSatisfy({ $0.isNumber }) {
                                let barcodeResults = (try? await lookup.fetchByBarcodeOFF(barcode: trimmed)) ?? []
                                results = barcodeResults.filter { ($0.mgPerServing ?? 0) > 0 }
                            } else {
                                // Run OFF + FDC in parallel for text queries
                                async let offTask = lookup.searchOFFByName(name: trimmed)
                                async let fdcTask = lookup.searchFDC(name: trimmed)
                                
                                let off = (try? await offTask) ?? []
                                let fdc = (try? await fdcTask) ?? []
                                
                                // Combine, filter, de-duplicate by name+amount
                                let combined = (off + fdc).filter { ($0.mgPerServing ?? 0) > 0 }
                                var seen = Set<String>()
                                results = combined.filter { r in
                                    let key = r.displayName.lowercased() + "-" + String(Int(r.mgPerServing ?? -1))
                                    return seen.insert(key).inserted
                                }
                            }
                        }
                    }
                    
                    if isLoading {
                        ProgressView()
                    }
                    
                    ForEach(results) { r in
                        Button {
                            selectedBeverage = BeverageType(name: r.displayName, defaultCaffeineContent: r.mgPerServing ?? 0, servingSize: selectedBeverage.servingSize, category: .coffee)
                            useCustomAmount = true
                            customAmount = String(Int(r.mgPerServing ?? 0))
                        } label: {
                            HStack {
                                Text(r.displayName)
                                Spacer()
                                Text(r.mgPerServing.map { "\(Int($0)) mg" } ?? "—")
                                    .foregroundColor(.secondary)
                            }
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
