//
//  BudgetsView.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 10/17/25.
//

import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Query private var budgets: [Budget]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddSheet = false
    @State private var selectedBudget: Budget?
    @State private var showingEditSheet = false
    @State private var budgetToDelete: Budget?
    @State private var showingDeleteConfirm = false

    private var currentMonthBudgets: [Budget] {
        let now = Date()
        return budgets.filter { $0.currentMonth.startOfMonth == now.startOfMonth }
    }

    var body: some View {
        NavigationStack {
            if currentMonthBudgets.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "No budgets yet",
                        systemImage: "dollarsign.circle",
                        description: Text("Create a budget to track spending goals for categories.")
                    )

                    Button(action: { showingAddSheet = true }) {
                        Label("Add Budget", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } else {
                List {
                    ForEach(currentMonthBudgets) { budget in
                        BudgetRowView(budget: budget)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedBudget = budget
                                showingEditSheet = true
                            }
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            budgetToDelete = currentMonthBudgets[index]
                            showingDeleteConfirm = true
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Budgets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !currentMonthBudgets.isEmpty {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBudgetSheet()
        }
        .sheet(isPresented: $showingEditSheet) {
            if let selectedBudget = selectedBudget {
                EditBudgetSheet(budget: selectedBudget)
            }
        }
        .alert("Delete Budget", isPresented: $showingDeleteConfirm, actions: {
            Button("Delete", role: .destructive) {
                if let budgetToDelete = budgetToDelete {
                    modelContext.delete(budgetToDelete)
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) { }
        }, message: {
            Text("Are you sure you want to delete this budget? This action cannot be undone.")
        })
    }
}

// MARK: - Budget Row Component

struct BudgetRowView: View {
    let budget: Budget

    private var percentageUsed: Double {
        budget.percentageUsed
    }

    private var progressBarColor: Color {
        if budget.isWarningThreshold {
            return .red
        } else if budget.isAlertThreshold {
            return .yellow
        } else {
            return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Category name and percentage
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: budget.category.symbolName)
                        .font(.title2)
                        .foregroundStyle(colorForCategory(budget.category.color))
                        .frame(width: 30)

                    Text(budget.category.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("\(percentageUsed, format: .percent.precision(.fractionLength(0)))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            // Progress bar with amounts
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))

                        // Progress fill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(progressBarColor)
                            .frame(width: geometry.size.width * CGFloat(min(percentageUsed / 100.0, 1.0)))
                    }
                }
                .frame(height: 12)

                // Amount details
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(budget.calculateCurrentSpending(), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Limit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(budget.monthlyLimit, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(budget.amountRemaining, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(budget.isWarningThreshold ? .red : budget.isAlertThreshold ? .orange : .green)
                    }
                }
            }

            // Notes if present
            if let notes = budget.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color(.systemBackground))
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Budget for \(budget.category.name)")
        .accessibilityValue("Spent \(budget.calculateCurrentSpending(), format: .currency(code: Locale.current.currency?.identifier ?? "USD")) of \(budget.monthlyLimit, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
    }
}

#Preview {
    BudgetsView()
        .modelContainer(PreviewData.previewModelContainer)
}
