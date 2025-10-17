//
//  BudgetProgressCard.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 10/17/25.
//

import SwiftUI
import SwiftData

struct BudgetProgressCard: View {
    @Query private var budgets: [Budget]

    private var currentMonthBudgets: [Budget] {
        let now = Date()
        return budgets.filter { $0.currentMonth.startOfMonth == now.startOfMonth }
    }

    private var topBudgets: [Budget] {
        currentMonthBudgets
            .sorted { $0.percentageUsed > $1.percentageUsed }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        if topBudgets.isEmpty {
            VStack(spacing: 8) {
                Text("Budget Overview")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle")
                        .font(.title)
                        .foregroundStyle(.secondary)

                    Text("Set budgets to track spending goals")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Budget Overview")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(spacing: 12) {
                    ForEach(topBudgets) { budget in
                        BudgetProgressRow(budget: budget)
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Budget Progress Row Component

struct BudgetProgressRow: View {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: budget.category.symbolName)
                        .font(.title3)
                        .foregroundStyle(colorForCategory(budget.category.color))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(budget.category.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("\(percentageUsed, format: .percent.precision(.fractionLength(0)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(budget.calculateCurrentSpending(), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressBarColor)
                        .frame(width: geometry.size.width * CGFloat(min(percentageUsed / 100.0, 1.0)))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Budget for \(budget.category.name)")
        .accessibilityValue("Spent \(budget.calculateCurrentSpending(), format: .currency(code: Locale.current.currency?.identifier ?? "USD")) of \(budget.monthlyLimit, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
    }
}

#Preview {
    BudgetProgressCard()
        .modelContainer(PreviewData.previewModelContainer)
}
