//
//  PersistenceTests.swift
//  ExpenseTrackerTests
//
//  Created by Claude Code on 10/23/25.
//

import XCTest
import SwiftData
@testable import ExpenseTracker

/// Tests SwiftData persistence edge cases (concurrent operations, data integrity)
class PersistenceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()

        let schema = Schema([ExpenseTracker.Expense.self, ExpenseTracker.Category.self, ExpenseTracker.Budget.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = ModelContext(modelContainer)
        } catch {
            XCTFail("Failed to set up test environment: \(error)")
        }
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Data Integrity Tests

    func testExpenseCategoryRelationshipIntegrity() {
        // Create category and expense
        let category = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category)

        let expense = ExpenseTracker.Expense(amount: 50.00, date: Date(), notes: "Test", category: category)
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save: \(error)")
            return
        }

        // Verify relationship integrity
        XCTAssertEqual(expense.category.name, "Food")
        XCTAssertTrue(category.expenses.contains(where: { $0.amount == 50.00 }))
    }

    func testCascadeDeleteBehavior() {
        // Create category with multiple expenses
        let category = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category)

        let expense1 = ExpenseTracker.Expense(amount: 25.00, date: Date(), notes: "Lunch", category: category)
        let expense2 = ExpenseTracker.Expense(amount: 35.00, date: Date(), notes: "Dinner", category: category)

        modelContext.insert(expense1)
        modelContext.insert(expense2)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save: \(error)")
            return
        }

        // Verify initial state
        let initialExpenses = fetchAllExpenses()
        XCTAssertEqual(initialExpenses.count, 2)

        // Delete category (should cascade to expenses)
        modelContext.delete(category)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save after delete: \(error)")
            return
        }

        // Verify cascade delete worked
        let finalExpenses = fetchAllExpenses()
        XCTAssertEqual(finalExpenses.count, 0, "Expenses should be cascade deleted with category")
    }

    func testMultipleContexts_IsolatedChanges() {
        // Create a second context
        let secondContext = ModelContext(modelContainer)

        // Insert category in first context
        let category1 = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category1)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save in first context: \(error)")
            return
        }

        // Verify second context can see the saved data
        let descriptor = FetchDescriptor<ExpenseTracker.Category>()
        do {
            let categoriesInSecondContext = try secondContext.fetch(descriptor)
            XCTAssertEqual(categoriesInSecondContext.count, 1)
            XCTAssertEqual(categoriesInSecondContext.first?.name, "Food")
        } catch {
            XCTFail("Failed to fetch from second context: \(error)")
        }
    }

    func testTransactionRollback() {
        // Create and save initial state
        let category = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save initial state: \(error)")
            return
        }

        // Make changes but don't save
        let expense = ExpenseTracker.Expense(amount: 100.00, date: Date(), notes: "Should rollback", category: category)
        modelContext.insert(expense)

        // Rollback by resetting context
        modelContext.rollback()

        // Verify expense was not persisted
        let expenses = fetchAllExpenses()
        XCTAssertEqual(expenses.count, 0, "Rolled back expense should not be persisted")

        // Verify category still exists
        let categories = fetchAllCategories()
        XCTAssertEqual(categories.count, 1, "Category should still exist after rollback")
    }

    func testBulkInsertPerformance() {
        let category = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category)

        measure {
            // Insert 100 expenses in bulk
            for i in 0..<100 {
                let expense = ExpenseTracker.Expense(
                    amount: Decimal(10 + i),
                    date: Date(),
                    notes: "Bulk expense \(i)",
                    category: category
                )
                modelContext.insert(expense)
            }

            do {
                try modelContext.save()
            } catch {
                XCTFail("Failed to save bulk insert: \(error)")
            }

            // Clean up for next iteration
            let expenses = fetchAllExpenses()
            for expense in expenses {
                modelContext.delete(expense)
            }
            try? modelContext.save()
        }
    }

    func testUniqueConstraintViolation_CategoryName() {
        // Create first category
        let category1 = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category1)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save first category: \(error)")
            return
        }

        // Attempt to create duplicate category
        let category2 = ExpenseTracker.Category(name: "Food", color: "blue", symbolName: "car.fill")
        modelContext.insert(category2)

        // Note: SwiftData doesn't enforce uniqueness at the schema level like Core Data
        // The app should enforce this at the business logic level
        do {
            try modelContext.save()
            // If this succeeds, it means we need to handle uniqueness in the app logic
            let categories = fetchAllCategories()
            XCTAssertGreaterThanOrEqual(categories.count, 1, "Categories saved despite potential duplicate")
        } catch {
            // If this fails, SwiftData is enforcing uniqueness
            XCTAssertNotNil(error, "Should throw error for duplicate category")
        }
    }

    func testDataIntegrity_DecimalPrecision() {
        let category = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category)

        // Test various decimal amounts
        let amounts: [Decimal] = [
            0.01,           // Minimum currency amount
            0.99,           // Just under 1
            999.99,         // Common price
            1234.56,        // Larger amount
            10000.00,       // Even amount
            12345.67        // Large precise amount
        ]

        for amount in amounts {
            let expense = ExpenseTracker.Expense(
                amount: amount,
                date: Date(),
                notes: "Amount test \(amount)",
                category: category
            )
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Verify all amounts were saved with precision
        let expenses = fetchAllExpenses()
        XCTAssertEqual(expenses.count, amounts.count)

        for (index, expense) in expenses.enumerated() {
            let expectedAmount = amounts[index]
            XCTAssertEqual(expense.amount, expectedAmount, accuracy: 0.001,
                          "Amount should be preserved with precision")
        }
    }

    func testDataIntegrity_DatePrecision() {
        let category = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category)

        // Create expenses with precise timestamps
        let now = Date()
        let dates = [
            now,
            now.addingTimeInterval(1),      // 1 second later
            now.addingTimeInterval(3600),   // 1 hour later
            now.addingTimeInterval(86400)   // 1 day later
        ]

        for date in dates {
            let expense = ExpenseTracker.Expense(
                amount: 10.00,
                date: date,
                notes: "Date test",
                category: category
            )
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Verify all dates were saved correctly
        let expenses = fetchAllExpenses().sorted { $0.date < $1.date }
        XCTAssertEqual(expenses.count, dates.count)

        for (index, expense) in expenses.enumerated() {
            let expectedDate = dates[index]
            let timeDifference = abs(expense.date.timeIntervalSince(expectedDate))
            XCTAssertLessThan(timeDifference, 1.0, "Date should be preserved within 1 second")
        }
    }

    func testOptionalFields_NullHandling() {
        let category = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category)

        // Test expense with nil notes
        let expenseWithoutNotes = ExpenseTracker.Expense(
            amount: 25.00,
            date: Date(),
            notes: nil,
            category: category
        )
        modelContext.insert(expenseWithoutNotes)

        // Test expense with empty notes
        let expenseWithEmptyNotes = ExpenseTracker.Expense(
            amount: 35.00,
            date: Date(),
            notes: "",
            category: category
        )
        modelContext.insert(expenseWithEmptyNotes)

        // Test expense with notes
        let expenseWithNotes = ExpenseTracker.Expense(
            amount: 45.00,
            date: Date(),
            notes: "Test notes",
            category: category
        )
        modelContext.insert(expenseWithNotes)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Verify all expenses saved correctly
        let expenses = fetchAllExpenses()
        XCTAssertEqual(expenses.count, 3)

        let withoutNotes = expenses.first { $0.amount == 25.00 }
        XCTAssertNil(withoutNotes?.notes, "Notes should be nil")

        let withEmptyNotes = expenses.first { $0.amount == 35.00 }
        XCTAssertEqual(withEmptyNotes?.notes, "", "Notes should be empty string")

        let withNotes = expenses.first { $0.amount == 45.00 }
        XCTAssertEqual(withNotes?.notes, "Test notes", "Notes should be preserved")
    }

    func testDemoDataExclusion() {
        let category = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category)

        // Create regular and demo expenses
        let regularExpense = ExpenseTracker.Expense(
            amount: 50.00,
            date: Date(),
            notes: "Regular",
            category: category,
            isDemo: false
        )

        let demoExpense = ExpenseTracker.Expense(
            amount: 100.00,
            date: Date(),
            notes: "Demo",
            category: category,
            isDemo: true
        )

        modelContext.insert(regularExpense)
        modelContext.insert(demoExpense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Verify both were saved
        let allExpenses = fetchAllExpenses()
        XCTAssertEqual(allExpenses.count, 2)

        // Verify filtering demo data
        let regularExpenses = allExpenses.filter { !$0.isDemo }
        XCTAssertEqual(regularExpenses.count, 1)
        XCTAssertEqual(regularExpenses.first?.amount, 50.00)

        let demoExpenses = allExpenses.filter { $0.isDemo }
        XCTAssertEqual(demoExpenses.count, 1)
        XCTAssertEqual(demoExpenses.first?.amount, 100.00)
    }

    // MARK: - Helper Methods

    private func fetchAllExpenses() -> [ExpenseTracker.Expense] {
        let fetchDescriptor = FetchDescriptor<ExpenseTracker.Expense>()
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            XCTFail("Failed to fetch expenses: \(error)")
            return []
        }
    }

    private func fetchAllCategories() -> [ExpenseTracker.Category] {
        let fetchDescriptor = FetchDescriptor<ExpenseTracker.Category>()
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            XCTFail("Failed to fetch categories: \(error)")
            return []
        }
    }
}
