//
//  AddBudgetSheet.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 10/17/25.
//

import SwiftUI
import SwiftData

struct AddBudgetSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var selectedCategory: Category?
    @State private var monthlyLimitText: String = ""
    @State private var notes: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    private var isValidInput: Bool {
        guard let _ = selectedCategory else { return false }
        guard let limit = Decimal(string: monthlyLimitText), limit > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    if categories.isEmpty {
                        Text("No categories available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select a category").tag(nil as Category?)
                            ForEach(categories, id: \.self) { category in
                                HStack(spacing: 8) {
                                    Image(systemName: category.symbolName)
                                        .foregroundStyle(colorForCategory(category.color))
                                    Text(category.name)
                                }
                                .tag(category as Category?)
                            }
                        }
                        .accessibilityLabel("Category")
                    }
                }

                Section("Monthly Limit") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $monthlyLimitText)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Monthly limit amount")
                    }
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .accessibilityLabel("Budget notes")
                }
            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(!isValidInput)
                }
            }
        }
        .alert("Invalid Input", isPresented: $showingError, actions: {
            Button("OK") { }
        }, message: {
            Text(errorMessage)
        })
    }

    private func saveBudget() {
        guard let category = selectedCategory else {
            errorMessage = "Please select a category"
            showingError = true
            return
        }

        guard let monthlyLimit = Decimal(string: monthlyLimitText), monthlyLimit > 0 else {
            errorMessage = "Monthly limit must be a positive number"
            showingError = true
            return
        }

        let budget = Budget(
            category: category,
            monthlyLimit: monthlyLimit,
            currentMonth: Date(),
            notes: notes.isEmpty ? nil : notes,
            isDemo: false
        )

        modelContext.insert(budget)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddBudgetSheet()
        .modelContainer(PreviewData.previewModelContainer)
}
