//
//  AddExpenseSheet.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    // Edit mode support
    let expense: Expense?

    // Form state
    @State private var amount: Decimal = 0
    @State private var selectedDate = Date()
    @State private var selectedCategory: Category?
    @State private var notes = ""
    @State private var showingDeleteConfirmation = false

    // Focus and validation
    @FocusState private var isAmountFocused: Bool
    @State private var amountText = ""

    private var isEditing: Bool {
        expense != nil
    }

    private var isValid: Bool {
        amount > 0 && selectedCategory != nil
    }

    private var amountError: String? {
        if !amountText.isEmpty && amount <= 0 {
            return "Amount must be greater than $0.00"
        }
        return nil
    }

    private var notesCharacterCount: Int {
        notes.count
    }

    init(expense: Expense? = nil) {
        self.expense = expense
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField(
                            "Amount",
                            value: $amount,
                            format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                        )
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                        .onChange(of: amount) { _, newValue in
                            amountText = String(describing: newValue)
                        }

                        if let error = amountError {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Amount")
                }

                Section("Date") {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Label {
                                Text(category.name)
                            } icon: {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(colorForCategory(category.color))
                                        .frame(width: 12, height: 12)
                                    Image(systemName: category.symbolName)
                                        .foregroundStyle(colorForCategory(category.color))
                                }
                            }
                            .tag(category as Category?)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("What was this for?", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .onChange(of: notes) { _, newValue in
                                if newValue.count > 200 {
                                    notes = String(newValue.prefix(200))
                                }
                            }

                        HStack {
                            Spacer()
                            Text("\(notesCharacterCount)/200")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Notes")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Edit Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Delete", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Update" : "Save") {
                        saveExpense()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isAmountFocused = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Delete Expense", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteExpense()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this expense? This action cannot be undone.")
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            setupInitialValues()
        }
    }

    private func setupInitialValues() {
        if let expense = expense {
            // Edit mode - populate with existing data
            amount = expense.amount
            selectedDate = expense.date
            selectedCategory = expense.category
            notes = expense.notes ?? ""
        } else {
            // Add mode - set defaults
            selectedDate = Date()
            selectedCategory = categories.first
        }
        amountText = String(describing: amount)
    }

    private func saveExpense() {
        guard isValid, let category = selectedCategory else { return }

        if let existingExpense = expense {
            // Update existing expense
            existingExpense.amount = amount
            existingExpense.date = selectedDate
            existingExpense.category = category
            existingExpense.notes = notes.isEmpty ? nil : notes
        } else {
            // Create new expense
            let newExpense = Expense(
                amount: amount,
                date: selectedDate,
                notes: notes.isEmpty ? nil : notes,
                category: category
            )
            modelContext.insert(newExpense)
        }

        do {
            try modelContext.save()

            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)

            dismiss()
        } catch {
            print("Failed to save expense: \(error)")
        }
    }

    private func deleteExpense() {
        guard let expense = expense else { return }

        modelContext.delete(expense)

        do {
            try modelContext.save()

            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)

            dismiss()
        } catch {
            print("Failed to delete expense: \(error)")
        }
    }

    private func colorForCategory(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "gray": return .gray
        case "green": return .green
        case "yellow": return .yellow
        default: return .blue
        }
    }
}

#Preview {
    AddExpenseSheet()
}

#Preview("Edit Mode") {
    AddExpenseSheet(
        expense: Expense(
            amount: Decimal(25.50),
            date: Date(),
            notes: "Sample expense",
            category: Category(name: "Food", color: "orange", symbolName: "fork.knife")
        )
    )
}
