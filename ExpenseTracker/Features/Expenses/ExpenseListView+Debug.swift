//
//  ExpenseListView+Debug.swift
//  ExpenseTracker
//
//  Created by automated refactor
//

import Foundation
import SwiftData

#if DEBUG
import SwiftUI

extension ExpenseListView {
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
}

#endif
