//
//  ExpenseListView.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
//

import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var expenseToDelete: Expense?
    @Environment(\.modelContext) private var modelContext
    
    private var filteredExpenses: [Expense] {
        if searchText.isEmpty {
            return expenses
        } else {
            return expenses.filter { expense in
                let notesMatch = expense.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                let categoryMatch = expense.category.name.localizedCaseInsensitiveContains(searchText)
                return notesMatch || categoryMatch
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredExpenses.isEmpty {
                    if expenses.isEmpty {
                        // No expenses at all
                        ContentUnavailableView(
                            "No expenses",
                            systemImage: "tray",
                            description: Text("Add your first expense.")
                        )
                    } else {
                        // No search results
                        ContentUnavailableView.search
                    }
                } else {
                    List {
                        ForEach(filteredExpenses) { expense in
                            ExpenseRowView(expense: expense)
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                    .animation(.snappy, value: filteredExpenses)
                }
            }
            .navigationTitle("Expenses")
            .searchable(text: $searchText, prompt: "Search expenses...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                #if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    if expenses.isEmpty {
                        Menu {
                            Button("Insert Sample Expenses (Debug)") {
                                insertSampleExpenses()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddSheet) {
                AddExpenseSheet()
            }
            .alert("Delete Expense", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this expense?")
            }
        }
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        for index in offsets {
            expenseToDelete = filteredExpenses[index]
            showingDeleteConfirmation = true
        }
    }
    
    private func confirmDelete() {
        guard let expenseToDelete = expenseToDelete else { return }
        
        modelContext.delete(expenseToDelete)
        
        do {
            try modelContext.save()
            // Success haptic
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } catch {
            print("Failed to delete expense: \(error)")
        }
        
        self.expenseToDelete = nil
    }
    
    #if DEBUG
    private func insertSampleExpenses() {
        let categories = try? modelContext.fetch(FetchDescriptor<Category>())
        guard let categories = categories, !categories.isEmpty else { return }
        
        let sampleExpenses = [
            Expense(
                amount: Decimal(25.50),
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                notes: "Lunch at downtown café",
                category: categories.first { $0.name == "Food" } ?? categories[0]
            ),
            Expense(
                amount: Decimal(15.00),
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                notes: "Bus fare",
                category: categories.first { $0.name == "Transportation" } ?? categories[0]
            ),
            Expense(
                amount: Decimal(45.99),
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                notes: "Movie tickets and popcorn",
                category: categories.first { $0.name == "Entertainment" } ?? categories[0]
            ),
            Expense(
                amount: Decimal(120.75),
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                notes: "Grocery shopping",
                category: categories.first { $0.name == "Shopping" } ?? categories[0]
            ),
            Expense(
                amount: Decimal(89.99),
                date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                notes: nil,
                category: categories.first { $0.name == "Bills" } ?? categories[0]
            )
        ]
        
        for expense in sampleExpenses {
            modelContext.insert(expense)
        }
        
        try? modelContext.save()
    }
    #endif
}

#Preview {
    ExpenseListView()
}