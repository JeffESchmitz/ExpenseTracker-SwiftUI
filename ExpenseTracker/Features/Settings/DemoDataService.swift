//
//  DemoDataService.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/30/25.
//

import Foundation
import SwiftData

struct DemoDataService {

    static func insertDemoData(modelContext: ModelContext, categories: [Category]) -> Int {
        print("🎭 DemoDataService: Starting demo data insertion")
        print("🎭 DemoDataService: Categories count: \(categories.count)")

        // Ensure we don't double-seed and have categories
        if let existingDemoCount = shouldSkipSeeding(modelContext: modelContext) {
            return existingDemoCount
        }

        guard hasCategories(categories) else { return 0 }

        let calendar = Calendar.current
        let now = Date()
        let expenseCount = createExpenseCount()
        print("🎭 DemoDataService: Will create \(expenseCount) demo expenses")

        // Sample notes for realistic variety
        let sampleNotes: [String?] = [
            "Coffee and pastry",
            "Grocery shopping",
            "Gas station fill-up",
            "Restaurant dinner",
            "Online shopping",
            "Pharmacy pickup",
            "Movie tickets",
            "Lunch with colleagues",
            "Weekend groceries",
            "Car maintenance",
            "Streaming subscription",
            "Phone bill",
            "Internet service",
            "Gym membership",
            "Haircut",
            "Book purchase",
            "Home supplies",
            "Pet food",
            "Clothing purchase",
            "Birthday gift",
            nil, nil, nil // Some expenses without notes
        ]

        var createdExpenses = 0

        for _ in 0..<expenseCount {
            if let expense = makeRandomExpense(
                now: now,
                calendar: calendar,
                categories: categories,
                sampleNotes: sampleNotes
            ) {
                modelContext.insert(expense)
                createdExpenses += 1
            }
        }

        return saveAndReturnCount(modelContext: modelContext, createdExpenses: createdExpenses)
    }

    private static func saveAndReturnCount(modelContext: ModelContext, createdExpenses: Int) -> Int {
        do {
            try modelContext.save()
            print("🎭 DemoDataService: Successfully created \(createdExpenses) demo expenses")
            return createdExpenses
        } catch {
            print("🎭 DemoDataService: Failed to save demo expenses: \(error)")
            return 0
        }
    }

    private static func shouldSkipSeeding(modelContext: ModelContext) -> Int? {
        let existingDemoCount = countDemoExpenses(modelContext: modelContext)
        if existingDemoCount > 0 {
            print("🎭 DemoDataService: Existing demo expenses: \(existingDemoCount)")
            print("🎭 DemoDataService: Demo data already exists, returning existing count")
            return existingDemoCount
        }

        return nil
    }

    private static func createExpenseCount() -> Int {
        return Int.random(in: 80...120)
    }

    private static func hasCategories(_ categories: [Category]) -> Bool {
        if categories.isEmpty {
            print("🎭 DemoDataService: No categories found, cannot generate demo data")
            return false
        }

        return true
    }

    static func removeDemoData(modelContext: ModelContext) -> Int {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.isDemo == true }
        )

        do {
            let demoExpenses = try modelContext.fetch(fetchDescriptor)
            let count = demoExpenses.count

            for expense in demoExpenses {
                modelContext.delete(expense)
            }

            try modelContext.save()
            return count
        } catch {
            print("Failed to remove demo expenses: \(error)")
            return 0
        }
    }

    static func countDemoExpenses(modelContext: ModelContext) -> Int {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.isDemo == true }
        )

        do {
            let demoExpenses = try modelContext.fetch(fetchDescriptor)
            let count = demoExpenses.count
            print("🎭 DemoDataService: Demo expense count: \(count)")
            return count
        } catch {
            print("🎭 DemoDataService: Failed to count demo expenses: \(error)")
            return 0
        }
    }

    private static func generateRealisticAmount(for categoryName: String) -> Decimal {
        let categoryLower = categoryName.lowercased()

        switch categoryLower {
        case let name where name.contains("food") || name.contains("restaurant") || name.contains("dining"):
            return Decimal(Double.random(in: 8.0...45.0))

        case let name where name.contains("transport") || name.contains("gas") || name.contains("fuel"):
            return Decimal(Double.random(in: 25.0...85.0))

        case let name where name.contains("shopping") || name.contains("retail"):
            return Decimal(Double.random(in: 15.0...120.0))

        case let name where name.contains("entertainment") || name.contains("movie") || name.contains("game"):
            return Decimal(Double.random(in: 10.0...35.0))

        case let name where name.contains("health") || name.contains("medical") || name.contains("pharmacy"):
            return Decimal(Double.random(in: 15.0...75.0))

        case let name where name.contains("utility") || name.contains("bill") || name.contains("subscription"):
            return Decimal(Double.random(in: 25.0...150.0))

        case let name where name.contains("travel") || name.contains("hotel"):
            return Decimal(Double.random(in: 50.0...300.0))

        case let name where name.contains("education") || name.contains("book"):
            return Decimal(Double.random(in: 20.0...80.0))

        default:
            return Decimal(Double.random(in: 10.0...100.0))
        }
    }

    // MARK: - Helpers for insertDemoData

    private static func makeRandomExpense(
        now: Date,
        calendar: Calendar,
        categories: [Category],
        sampleNotes: [String?]
    ) -> Expense? {
        // Random date in last 6-12 months
        let monthsBack = Int.random(in: 1...12)
        let daysBack = Int.random(in: 0...30)

        guard let baseDate = calendar.date(byAdding: .month, value: -monthsBack, to: now),
              let expenseDate = calendar.date(byAdding: .day, value: -daysBack, to: baseDate) else {
            return nil
        }

        // Random category
        guard let randomCategory = categories.randomElement() else { return nil }

        // Realistic amount based on category
        let amount = generateRealisticAmount(for: randomCategory.name)

        // Random notes (some expenses have no notes)
        let notes = sampleNotes.randomElement() ?? nil

        return Expense(
            amount: amount,
            date: expenseDate,
            notes: notes,
            category: randomCategory,
            isDemo: true
        )
    }
}
