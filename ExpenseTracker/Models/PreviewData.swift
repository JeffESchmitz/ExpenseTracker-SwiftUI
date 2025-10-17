//
//  PreviewData.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 10/17/25.
//

import Foundation
import SwiftData

// MARK: - Preview Data Generation

struct PreviewData {
    static let previewModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            Category.self,
            Budget.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])

        // Create categories
        let foodCategory = Category(name: "Food", color: "orange", symbolName: "fork.knife")
        let transportCategory = Category(name: "Transportation", color: "blue", symbolName: "car.fill")
        let entertainmentCategory = Category(name: "Entertainment", color: "purple", symbolName: "tv.fill")
        let shoppingCategory = Category(name: "Shopping", color: "pink", symbolName: "bag.fill")

        let context = ModelContext(container)
        context.insert(foodCategory)
        context.insert(transportCategory)
        context.insert(entertainmentCategory)
        context.insert(shoppingCategory)

        // Create sample expenses for current month
        let now = Date()
        let startOfMonth = now.startOfMonth

        // Food expenses (total ~$150 out of $200 budget = 75%)
        context.insert(Expense(amount: 45, date: startOfMonth.addingTimeInterval(86400 * 2), notes: "Groceries", category: foodCategory, isDemo: true))
        context.insert(Expense(amount: 35, date: startOfMonth.addingTimeInterval(86400 * 5), notes: "Restaurant", category: foodCategory, isDemo: true))
        context.insert(Expense(amount: 28, date: startOfMonth.addingTimeInterval(86400 * 10), notes: "Lunch", category: foodCategory, isDemo: true))
        context.insert(Expense(amount: 42, date: startOfMonth.addingTimeInterval(86400 * 15), notes: "Groceries", category: foodCategory, isDemo: true))

        // Transportation expenses (total ~$85 out of $150 budget = 56%)
        context.insert(Expense(amount: 50, date: startOfMonth.addingTimeInterval(86400 * 3), notes: "Gas", category: transportCategory, isDemo: true))
        context.insert(Expense(amount: 35, date: startOfMonth.addingTimeInterval(86400 * 12), notes: "Car maintenance", category: transportCategory, isDemo: true))

        // Entertainment expenses (total ~$130 out of $100 budget = 130% - over budget!)
        context.insert(Expense(amount: 40, date: startOfMonth.addingTimeInterval(86400 * 4), notes: "Movie night", category: entertainmentCategory, isDemo: true))
        context.insert(Expense(amount: 55, date: startOfMonth.addingTimeInterval(86400 * 8), notes: "Concert tickets", category: entertainmentCategory, isDemo: true))
        context.insert(Expense(amount: 35, date: startOfMonth.addingTimeInterval(86400 * 14), notes: "Streaming services", category: entertainmentCategory, isDemo: true))

        // Shopping expenses (total ~$90 out of $200 budget = 45%)
        context.insert(Expense(amount: 60, date: startOfMonth.addingTimeInterval(86400 * 7), notes: "Clothes", category: shoppingCategory, isDemo: true))
        context.insert(Expense(amount: 30, date: startOfMonth.addingTimeInterval(86400 * 16), notes: "Shoes", category: shoppingCategory, isDemo: true))

        // Create sample budgets
        context.insert(Budget(
            category: foodCategory,
            monthlyLimit: 200,
            currentMonth: now,
            notes: "Food and groceries",
            isDemo: true
        ))

        context.insert(Budget(
            category: transportCategory,
            monthlyLimit: 150,
            currentMonth: now,
            notes: "Gas and maintenance",
            isDemo: true
        ))

        context.insert(Budget(
            category: entertainmentCategory,
            monthlyLimit: 100,
            currentMonth: now,
            notes: "Entertainment",
            isDemo: true
        ))

        context.insert(Budget(
            category: shoppingCategory,
            monthlyLimit: 200,
            currentMonth: now,
            notes: "Clothing and shopping",
            isDemo: true
        ))

        try? context.save()
        return container
    }()
}
