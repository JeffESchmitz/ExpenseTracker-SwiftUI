//
//  Budget.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 10/17/25.
//

import Foundation
import SwiftData

enum BudgetError: Error {
    case invalidLimit(String)
}

@Model
final class Budget {
    @Attribute(.unique) var id: UUID

    @Relationship
    var category: Category

    var monthlyLimit: Decimal
    var currentMonth: Date  // Stored as first day of the month
    var notes: String?
    var isDemo: Bool

    init(
        id: UUID = UUID(),
        category: Category,
        monthlyLimit: Decimal,
        currentMonth: Date,
        notes: String? = nil,
        isDemo: Bool = false
    ) throws {
        // Validate monthlyLimit is positive
        guard monthlyLimit > 0 else {
            throw BudgetError.invalidLimit("Budget monthly limit must be positive, got \(monthlyLimit)")
        }

        self.id = id
        self.category = category
        self.monthlyLimit = monthlyLimit
        self.currentMonth = currentMonth.startOfMonth
        self.notes = notes
        self.isDemo = isDemo
    }

    /// Calculate the total spending for this budget's category in the current month
    func calculateCurrentSpending() -> Decimal {
        let monthStart = currentMonth.startOfMonth
        let monthEnd = currentMonth.endOfMonth

        let relevantExpenses = category.expenses.filter { expense in
            expense.date >= monthStart && expense.date <= monthEnd && !expense.isDemo
        }

        return relevantExpenses.reduce(0) { $0 + $1.amount }
    }

    /// Percentage of budget spent (0-100+)
    var percentageUsed: Double {
        let currentSpending = calculateCurrentSpending()
        let percentage = (NSDecimalNumber(decimal: currentSpending).doubleValue / NSDecimalNumber(decimal: monthlyLimit).doubleValue) * 100
        return percentage.isFinite ? max(0, percentage) : 0
    }

    /// Amount remaining in budget
    var amountRemaining: Decimal {
        let currentSpending = calculateCurrentSpending()
        return max(0, monthlyLimit - currentSpending)
    }

    /// True if spending >= 75% of limit
    var isAlertThreshold: Bool {
        percentageUsed >= 75.0
    }

    /// True if spending >= 90% of limit
    var isWarningThreshold: Bool {
        percentageUsed >= 90.0
    }
}

// MARK: - Helper Extensions for Date calculations

extension Date {
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: self) else { return self }
        return interval.end.addingTimeInterval(-1)
    }
}
