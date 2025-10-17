//
//  EditBudgetSheet.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 10/17/25.
//

import SwiftUI
import SwiftData

struct EditBudgetSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    let budget: Budget

    @State private var monthlyLimitText: String = ""
    @State private var notes: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    private var isValidInput: Bool {
        guard let limit = Decimal(string: monthlyLimitText), limit > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    HStack(spacing: 8) {
                        Image(systemName: budget.category.symbolName)
                            .foregroundStyle(colorForCategory(budget.category.color))
                        Text(budget.category.name)
                            .font(.body)
                    }
                    .foregroundStyle(.secondary)
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
            .navigationTitle("Edit Budget")
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
        .onAppear {
            monthlyLimitText = "\(NSDecimalNumber(decimal: budget.monthlyLimit))"
            notes = budget.notes ?? ""
        }
        .alert("Invalid Input", isPresented: $showingError, actions: {
            Button("OK") { }
        }, message: {
            Text(errorMessage)
        })
    }

    private func saveBudget() {
        guard let monthlyLimit = Decimal(string: monthlyLimitText), monthlyLimit > 0 else {
            errorMessage = "Monthly limit must be a positive number"
            showingError = true
            return
        }

        budget.monthlyLimit = monthlyLimit
        budget.notes = notes.isEmpty ? nil : notes

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = PreviewData.previewModelContainer
    let context = ModelContext(container)

    // Fetch a budget from preview data
    var budget: Budget?
    do {
        let descriptor = FetchDescriptor<Budget>()
        let budgets = try context.fetch(descriptor)
        budget = budgets.first
    } catch {
        print("Error fetching budget: \(error)")
    }

    if let budget = budget {
        return AnyView(
            EditBudgetSheet(budget: budget)
                .modelContainer(container)
        )
    }

    return AnyView(Text("No budgets to preview"))
}
