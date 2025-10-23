//
//  BudgetEdgeCaseTests.swift
//  ExpenseTrackerTests
//
//  Created by Claude Code on 10/23/25.
//

import XCTest
import SwiftData
@testable import ExpenseTracker

/// Tests budget calculations with edge cases
class BudgetEdgeCaseTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testCategory: ExpenseTracker.Category!

    override func setUp() {
        super.setUp()

        let schema = Schema([ExpenseTracker.Expense.self, ExpenseTracker.Category.self, ExpenseTracker.Budget.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = ModelContext(modelContainer)

            testCategory = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
            modelContext.insert(testCategory)
            try modelContext.save()

        } catch {
            XCTFail("Failed to set up test environment: \(error)")
        }
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        testCategory = nil
        super.tearDown()
    }

    // MARK: - Edge Case Tests

    func testBudget_VerySmallLimit() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(0.01),  // 1 cent
                currentMonth: Date()
            )
            modelContext.insert(budget)
            try modelContext.save()

            XCTAssertEqual(budget.monthlyLimit, Decimal(0.01))
            XCTAssertEqual(budget.percentageUsed, 0.0)
            XCTAssertEqual(budget.amountRemaining, Decimal(0.01))
        } catch {
            XCTFail("Should allow very small positive limit: \(error)")
        }
    }

    func testBudget_VeryLargeLimit() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(999999.99),  // Nearly 1 million
                currentMonth: Date()
            )
            modelContext.insert(budget)
            try modelContext.save()

            XCTAssertEqual(budget.monthlyLimit, Decimal(999999.99))
            XCTAssertEqual(budget.percentageUsed, 0.0)
            XCTAssertEqual(budget.amountRemaining, Decimal(999999.99))
        } catch {
            XCTFail("Should allow very large limit: \(error)")
        }
    }

    func testBudget_SpendingExactlyAtLimit() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: Date()
            )
            modelContext.insert(budget)

            let expense = ExpenseTracker.Expense(
                amount: Decimal(500),  // Exactly at limit
                date: Date(),
                notes: "At limit",
                category: testCategory
            )
            modelContext.insert(expense)
            try modelContext.save()

            XCTAssertEqual(budget.percentageUsed, 100.0, accuracy: 0.01)
            XCTAssertEqual(budget.amountRemaining, Decimal(0))
            XCTAssertFalse(budget.isAlertThreshold, "At 100%, should not be in alert threshold (75-89%)")
            XCTAssertTrue(budget.isWarningThreshold, "At 100%, should be in warning threshold (90%+)")
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_SpendingSlightlyOverLimit() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: Date()
            )
            modelContext.insert(budget)

            let expense = ExpenseTracker.Expense(
                amount: Decimal(500.01),  // Slightly over
                date: Date(),
                notes: "Over limit",
                category: testCategory
            )
            modelContext.insert(expense)
            try modelContext.save()

            XCTAssertGreaterThan(budget.percentageUsed, 100.0)
            XCTAssertEqual(budget.amountRemaining, Decimal(0), "Amount remaining should be 0, not negative")
            XCTAssertTrue(budget.isWarningThreshold)
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_SpendingWayOverLimit() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: Date()
            )
            modelContext.insert(budget)

            let expense = ExpenseTracker.Expense(
                amount: Decimal(1000),  // Double the limit
                date: Date(),
                notes: "Way over limit",
                category: testCategory
            )
            modelContext.insert(expense)
            try modelContext.save()

            XCTAssertEqual(budget.percentageUsed, 200.0, accuracy: 0.01)
            XCTAssertEqual(budget.amountRemaining, Decimal(0))
            XCTAssertTrue(budget.isWarningThreshold)
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_MultipleSmallExpenses() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(100),
                currentMonth: Date()
            )
            modelContext.insert(budget)

            // Add 100 expenses of $0.50 each = $50 total
            for i in 0..<100 {
                let expense = ExpenseTracker.Expense(
                    amount: Decimal(0.50),
                    date: Date(),
                    notes: "Small expense \(i)",
                    category: testCategory
                )
                modelContext.insert(expense)
            }
            try modelContext.save()

            XCTAssertEqual(budget.calculateCurrentSpending(), Decimal(50))
            XCTAssertEqual(budget.percentageUsed, 50.0, accuracy: 0.01)
            XCTAssertEqual(budget.amountRemaining, Decimal(50))
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_ExpensesOnMonthBoundary() {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = now.startOfMonth
        let monthEnd = now.endOfMonth

        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: now
            )
            modelContext.insert(budget)

            // Expense at exact start of month
            let startExpense = ExpenseTracker.Expense(
                amount: Decimal(100),
                date: monthStart,
                notes: "Start of month",
                category: testCategory
            )
            modelContext.insert(startExpense)

            // Expense at exact end of month
            let endExpense = ExpenseTracker.Expense(
                amount: Decimal(100),
                date: monthEnd,
                notes: "End of month",
                category: testCategory
            )
            modelContext.insert(endExpense)

            // Expense one second after month end (should not count)
            let afterEndExpense = ExpenseTracker.Expense(
                amount: Decimal(50),
                date: monthEnd.addingTimeInterval(1),
                notes: "After month end",
                category: testCategory
            )
            modelContext.insert(afterEndExpense)

            try modelContext.save()

            // Should only count start and end expenses
            XCTAssertEqual(budget.calculateCurrentSpending(), Decimal(200),
                          "Should include expenses at start and end, but not after")
            XCTAssertEqual(budget.percentageUsed, 40.0, accuracy: 0.01)
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_ExpensesInDifferentMonths() {
        let calendar = Calendar.current
        let now = Date()

        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: now
            )
            modelContext.insert(budget)

            // This month
            let thisMonthExpense = ExpenseTracker.Expense(
                amount: Decimal(100),
                date: now,
                notes: "This month",
                category: testCategory
            )
            modelContext.insert(thisMonthExpense)

            // Last month
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            let lastMonthExpense = ExpenseTracker.Expense(
                amount: Decimal(200),
                date: lastMonth,
                notes: "Last month",
                category: testCategory
            )
            modelContext.insert(lastMonthExpense)

            // Next month
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: now)!
            let nextMonthExpense = ExpenseTracker.Expense(
                amount: Decimal(300),
                date: nextMonth,
                notes: "Next month",
                category: testCategory
            )
            modelContext.insert(nextMonthExpense)

            try modelContext.save()

            // Should only count this month's expense
            XCTAssertEqual(budget.calculateCurrentSpending(), Decimal(100))
            XCTAssertEqual(budget.percentageUsed, 20.0, accuracy: 0.01)
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_MixedDemoAndRegularExpenses() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: Date()
            )
            modelContext.insert(budget)

            // Regular expenses
            let regularExpense1 = ExpenseTracker.Expense(
                amount: Decimal(100),
                date: Date(),
                notes: "Regular 1",
                category: testCategory,
                isDemo: false
            )
            modelContext.insert(regularExpense1)

            let regularExpense2 = ExpenseTracker.Expense(
                amount: Decimal(150),
                date: Date(),
                notes: "Regular 2",
                category: testCategory,
                isDemo: false
            )
            modelContext.insert(regularExpense2)

            // Demo expenses (should not count)
            let demoExpense1 = ExpenseTracker.Expense(
                amount: Decimal(200),
                date: Date(),
                notes: "Demo 1",
                category: testCategory,
                isDemo: true
            )
            modelContext.insert(demoExpense1)

            let demoExpense2 = ExpenseTracker.Expense(
                amount: Decimal(300),
                date: Date(),
                notes: "Demo 2",
                category: testCategory,
                isDemo: true
            )
            modelContext.insert(demoExpense2)

            try modelContext.save()

            // Should only count regular expenses
            XCTAssertEqual(budget.calculateCurrentSpending(), Decimal(250),
                          "Should exclude demo expenses")
            XCTAssertEqual(budget.percentageUsed, 50.0, accuracy: 0.01)
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_AlertThresholdBoundary() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(100),
                currentMonth: Date()
            )
            modelContext.insert(budget)

            // Test at 74.9% - should NOT trigger alert
            let expense1 = ExpenseTracker.Expense(
                amount: Decimal(74.90),
                date: Date(),
                notes: "Below threshold",
                category: testCategory
            )
            modelContext.insert(expense1)
            try modelContext.save()

            XCTAssertFalse(budget.isAlertThreshold, "74.9% should not trigger alert")
            XCTAssertFalse(budget.isWarningThreshold, "74.9% should not trigger warning")

            // Add to reach exactly 75%
            let expense2 = ExpenseTracker.Expense(
                amount: Decimal(0.10),
                date: Date(),
                notes: "Reach threshold",
                category: testCategory
            )
            modelContext.insert(expense2)
            try modelContext.save()

            XCTAssertTrue(budget.isAlertThreshold, "75% should trigger alert")
            XCTAssertFalse(budget.isWarningThreshold, "75% should not trigger warning")
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_WarningThresholdBoundary() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(100),
                currentMonth: Date()
            )
            modelContext.insert(budget)

            // Test at 89.9% - should trigger alert but NOT warning
            let expense1 = ExpenseTracker.Expense(
                amount: Decimal(89.90),
                date: Date(),
                notes: "Below warning threshold",
                category: testCategory
            )
            modelContext.insert(expense1)
            try modelContext.save()

            XCTAssertTrue(budget.isAlertThreshold, "89.9% should trigger alert")
            XCTAssertFalse(budget.isWarningThreshold, "89.9% should not trigger warning")

            // Add to reach exactly 90%
            let expense2 = ExpenseTracker.Expense(
                amount: Decimal(0.10),
                date: Date(),
                notes: "Reach warning threshold",
                category: testCategory
            )
            modelContext.insert(expense2)
            try modelContext.save()

            XCTAssertTrue(budget.isAlertThreshold, "90% should trigger alert")
            XCTAssertTrue(budget.isWarningThreshold, "90% should trigger warning")
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_DecimalPrecision() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(string: "123.45")!,
                currentMonth: Date()
            )
            modelContext.insert(budget)

            let expense = ExpenseTracker.Expense(
                amount: Decimal(string: "67.89")!,
                date: Date(),
                notes: "Precise amount",
                category: testCategory
            )
            modelContext.insert(expense)
            try modelContext.save()

            let spending = budget.calculateCurrentSpending()
            let remaining = budget.amountRemaining

            XCTAssertEqual(spending, Decimal(string: "67.89")!, "Should preserve decimal precision")
            XCTAssertEqual(remaining, Decimal(string: "55.56")!, "Should calculate precise remainder")
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_MultipleBudgetsForDifferentCategories() {
        // Create second category
        let transportCategory = ExpenseTracker.Category(
            name: "Transportation",
            color: "blue",
            symbolName: "car.fill"
        )
        modelContext.insert(transportCategory)

        do {
            // Create budgets for both categories
            let foodBudget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: Date()
            )
            modelContext.insert(foodBudget)

            let transportBudget = try ExpenseTracker.Budget(
                category: transportCategory,
                monthlyLimit: Decimal(200),
                currentMonth: Date()
            )
            modelContext.insert(transportBudget)

            // Add expenses to both categories
            let foodExpense = ExpenseTracker.Expense(
                amount: Decimal(100),
                date: Date(),
                notes: "Food",
                category: testCategory
            )
            modelContext.insert(foodExpense)

            let transportExpense = ExpenseTracker.Expense(
                amount: Decimal(50),
                date: Date(),
                notes: "Transport",
                category: transportCategory
            )
            modelContext.insert(transportExpense)

            try modelContext.save()

            // Verify budgets are independent
            XCTAssertEqual(foodBudget.calculateCurrentSpending(), Decimal(100))
            XCTAssertEqual(transportBudget.calculateCurrentSpending(), Decimal(50))

            XCTAssertEqual(foodBudget.percentageUsed, 20.0, accuracy: 0.01)
            XCTAssertEqual(transportBudget.percentageUsed, 25.0, accuracy: 0.01)
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_DateNormalization() {
        let calendar = Calendar.current
        let now = Date()

        // Create date in middle of month
        let midMonth = calendar.date(byAdding: .day, value: 15, to: now.startOfMonth)!

        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: midMonth
            )

            // Budget should normalize to start of month
            XCTAssertEqual(budget.currentMonth, midMonth.startOfMonth,
                          "Budget date should be normalized to start of month")
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testBudget_PerformanceWithManyExpenses() {
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(10000),
                currentMonth: Date()
            )
            modelContext.insert(budget)

            // Create 1000 small expenses
            for i in 0..<1000 {
                let expense = ExpenseTracker.Expense(
                    amount: Decimal(5),
                    date: Date(),
                    notes: "Expense \(i)",
                    category: testCategory
                )
                modelContext.insert(expense)
            }
            try modelContext.save()

            // Measure performance of calculation
            measure {
                let spending = budget.calculateCurrentSpending()
                XCTAssertEqual(spending, Decimal(5000))
            }
        } catch {
            XCTFail("Failed: \(error)")
        }
    }
}
