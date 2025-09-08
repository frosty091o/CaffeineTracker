//
//  AddEntryView.swift
//  CaffeineTracker
//
//  Created by Ethan on 3/9/2025.
//

import SwiftUI

// quick form to add a drink. pick a preset or "Custom…", set mg, add notes, save.

struct AddEntryView: View {
    let lookup = CaffeineLookupService(fdcKey: "b0cehDATvB5rLhcsQTDDtO6GZia3fSeYjNzUAOBf")
    @EnvironmentObject var manager: CaffeineIntakeManager
    @Environment(\.dismiss) var dismiss

    // "Custom…" option so you can type your own drink
    private let customPlaceholder = BeverageType(
        name: "Custom",
        defaultCaffeineContent: 0,
        servingSize: BeverageType.espresso.servingSize,
        category: .coffee // adjust if you have .custom/.other
    )
    
    // form state
    @State private var selectedBeverage = BeverageType.espresso
    @State private var customName = ""
    @State private var customAmount = ""
    @State private var useCustomAmount = false
    @State private var notes = ""
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var query = ""
    @State private var results: [LookupResult] = []
    @State private var isLoading = false
    
    // caffeine we save (uses custom when toggled)
    var calculatedCaffeine: Double {
        if useCustomAmount {
            return Double(customAmount) ?? 0
        }
        return selectedBeverage.defaultCaffeineContent
    }
    
    // enable Add only when > 0 mg
    var isValidEntry: Bool {
        calculatedCaffeine > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                // presets + a "Custom…" at the end
                Section(header: Text("Select Beverage")) {
                    Picker("Beverage", selection: $selectedBeverage) {
                        ForEach(BeverageType.allPresets, id: \.name) { beverage in
                            Text(beverage.name).tag(beverage)
                        }
                        Text("Custom…").tag(customPlaceholder)
                    }
                    .pickerStyle(MenuPickerStyle())
                    // when Custom is picked, flip on custom amount
                    .onChange(of: selectedBeverage) { newValue in
                        if newValue.name == "Custom" { useCustomAmount = true }
                    }

                    // show name only for Custom
                    if selectedBeverage.name == "Custom" {
                        TextField("Enter beverage name", text: $customName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .foregroundColor(.primary)
                            .font(.body)
                    }
                }
                
                // type your own mg
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
                        // preset default mg (read‑only)
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text("\(Int(selectedBeverage.defaultCaffeineContent)) mg")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // search by name or barcode
                Section(header: Text("Lookup (Optional)")) {
                    TextField("Search by name or barcode", text: $query)
                    
                    Button("Search") {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            results = []
                            
                            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // barcode -> OFF; name -> OFF + USDA (in parallel)
                            // looks like a barcode
                            if !trimmed.isEmpty && trimmed.allSatisfy({ $0.isNumber }) {
                                let barcodeResults = (try? await lookup.fetchByBarcodeOFF(barcode: trimmed)) ?? []
                                results = barcodeResults.filter { ($0.mgPerServing ?? 0) > 0 }
                            } else {
                                // fire both
                                async let offTask = lookup.searchOFFByName(name: trimmed)
                                async let fdcTask = lookup.searchFDC(name: trimmed)
                                
                                let off = (try? await offTask) ?? []
                                let fdc = (try? await fdcTask) ?? []
                                
                                // merge, keep items with mg, dedupe by name+mg
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
                    
                    // tap to fill the form
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
                
                // high number
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
                
                // will exceed today’s limit
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
                // cancel
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                // save
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
        // quick checks
        guard calculatedCaffeine > 0 else {
            errorMessage = "Caffeine amount must be greater than 0"
            showingError = true
            return
        }
        
        // >1000 mg is probably a mistake
        guard calculatedCaffeine < 1000 else {
            errorMessage = "Caffeine amount seems too high. Please check."
            showingError = true
            return
        }
        
        // build custom beverage when needed
        let beverageForEntry: BeverageType
        if selectedBeverage.name == "Custom" {
            let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                errorMessage = "Please enter a name for your custom beverage."
                showingError = true
                return
            }
            beverageForEntry = BeverageType(
                name: trimmed,
                defaultCaffeineContent: calculatedCaffeine,
                servingSize: BeverageType.espresso.servingSize,
                category: .coffee
            )
        } else {
            beverageForEntry = selectedBeverage
        }
        
        // save it
        let entry = CaffeineEntry(
            beverageType: beverageForEntry,
            caffeineAmount: calculatedCaffeine,
            notes: notes.isEmpty ? nil : notes
        )
        
        manager.addEntry(entry)
        dismiss()
    }
}
