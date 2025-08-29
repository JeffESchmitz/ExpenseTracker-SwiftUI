//
//  AddExpenseSheet.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
//

import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    
    @State private var amount = ""
    @State private var selectedDate = Date()
    @State private var selectedCategory: Category?
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .disabled(true) // Placeholder - non-functional
                }
                
                Section("Date") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .disabled(true) // Placeholder - non-functional
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            HStack {
                                Image(systemName: category.symbolName)
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                    .disabled(true) // Placeholder - non-functional
                }
                
                Section("Notes") {
                    TextField("Optional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .disabled(true) // Placeholder - non-functional
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        // Placeholder - will be implemented in next feature
                    }
                    .disabled(true) // Placeholder - non-functional
                    .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            selectedCategory = categories.first
        }
    }
}

#Preview {
    AddExpenseSheet()
}