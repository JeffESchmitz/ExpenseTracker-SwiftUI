//
//  PerformanceTests.swift
//  ExpenseTrackerTests
//
//  Created by Claude Code on 10/23/25.
//

import XCTest
import SwiftData
@testable import ExpenseTracker

/// Tests performance with large datasets (100+, 1000+ expenses)
class PerformanceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testCategories: [ExpenseTracker.Category]!

    override func setUp() {
        super.setUp()

        let schema = Schema([ExpenseTracker.Expense.self, ExpenseTracker.Category.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = ModelContext(modelContainer)

            // Create test categories
            let categories = [
                ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife"),
                ExpenseTracker.Category(name: "Transportation", color: "blue", symbolName: "car.fill"),
                ExpenseTracker.Category(name: "Entertainment", color: "purple", symbolName: "tv.fill"),
                ExpenseTracker.Category(name: "Bills", color: "red", symbolName: "doc.text.fill"),
                ExpenseTracker.Category(name: "Shopping", color: "green", symbolName: "bag.fill")
            ]

            for category in categories {
                modelContext.insert(category)
            }
            try modelContext.save()
            testCategories = categories

        } catch {
            XCTFail("Failed to set up test environment: \(error)")
        }
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        testCategories = nil
        super.tearDown()
    }

    // MARK: - Large Dataset Tests (100 expenses)

    func testPerformance_FetchAll_100Expenses() {
        createExpenses(count: 100)

        measure {
            _ = fetchAllExpenses()
        }
    }

    func testPerformance_FilterByDate_100Expenses() {
        createExpenses(count: 100)

        let filter = DateRangeFilter.last30Days
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range")
            return
        }

        measure {
            let expenses = fetchAllExpenses()
            _ = expenses.filter { expense in
                expense.date >= dateRange.start && expense.date <= dateRange.end
            }
        }
    }

    func testPerformance_FilterByCategory_100Expenses() {
        createExpenses(count: 100)

        measure {
            let expenses = fetchAllExpenses()
            _ = expenses.filter { expense in
                expense.category.name == "Food"
            }
        }
    }

    func testPerformance_ComplexFilter_100Expenses() {
        createExpenses(count: 100)

        let filter = DateRangeFilter.last30Days
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range")
            return
        }

        measure {
            let expenses = fetchAllExpenses()
            _ = expenses.filter { expense in
                let dateMatch = expense.date >= dateRange.start && expense.date <= dateRange.end
                let categoryMatch = ["Food", "Transportation"].contains(expense.category.name)
                let amountMatch = expense.amount >= 10 && expense.amount <= 100
                return dateMatch && categoryMatch && amountMatch
            }
        }
    }

    func testPerformance_GroupByMonth_100Expenses() {
        createExpenses(count: 100)

        measure {
            let expenses = fetchAllExpenses()
            let calendar = Calendar.current

            _ = Dictionary(grouping: expenses) { expense in
                calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
            }
        }
    }

    func testPerformance_GroupByCategory_100Expenses() {
        createExpenses(count: 100)

        measure {
            let expenses = fetchAllExpenses()
            _ = Dictionary(grouping: expenses) { $0.category.name }
        }
    }

    func testPerformance_CalculateTotals_100Expenses() {
        createExpenses(count: 100)

        measure {
            let expenses = fetchAllExpenses()
            _ = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        }
    }

    func testPerformance_Sort_100Expenses() {
        createExpenses(count: 100)

        measure {
            let expenses = fetchAllExpenses()
            _ = expenses.sorted { $0.date > $1.date }
        }
    }

    // MARK: - Very Large Dataset Tests (1000 expenses)

    func testPerformance_FetchAll_1000Expenses() {
        createExpenses(count: 1000)

        measure {
            _ = fetchAllExpenses()
        }
    }

    func testPerformance_FilterByDate_1000Expenses() {
        createExpenses(count: 1000)

        let filter = DateRangeFilter.last30Days
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range")
            return
        }

        measure {
            let expenses = fetchAllExpenses()
            _ = expenses.filter { expense in
                expense.date >= dateRange.start && expense.date <= dateRange.end
            }
        }
    }

    func testPerformance_ComplexFilter_1000Expenses() {
        createExpenses(count: 1000)

        let filter = DateRangeFilter.last30Days
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range")
            return
        }

        measure {
            let expenses = fetchAllExpenses()
            _ = expenses.filter { expense in
                let dateMatch = expense.date >= dateRange.start && expense.date <= dateRange.end
                let categoryMatch = ["Food", "Transportation", "Entertainment"].contains(expense.category.name)
                let amountMatch = expense.amount >= 10 && expense.amount <= 200
                let searchMatch = expense.notes?.contains("expense") ?? false
                return dateMatch && categoryMatch && amountMatch && searchMatch
            }
        }
    }

    func testPerformance_GroupByMonth_1000Expenses() {
        createExpenses(count: 1000)

        measure {
            let expenses = fetchAllExpenses()
            let calendar = Calendar.current

            _ = Dictionary(grouping: expenses) { expense in
                calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
            }
        }
    }

    func testPerformance_CategoryAggregation_1000Expenses() {
        createExpenses(count: 1000)

        measure {
            let expenses = fetchAllExpenses()
            let groupedByCategory = Dictionary(grouping: expenses) { $0.category.name }

            _ = groupedByCategory.map { (categoryName, categoryExpenses) in
                (categoryName, categoryExpenses.reduce(Decimal.zero) { $0 + $1.amount })
            }
        }
    }

    func testPerformance_Sort_1000Expenses() {
        createExpenses(count: 1000)

        measure {
            let expenses = fetchAllExpenses()
            _ = expenses.sorted { $0.date > $1.date }
        }
    }

    // MARK: - Stress Tests

    func testStress_MultipleFiltersInSequence() {
        createExpenses(count: 500)

        measure {
            let expenses = fetchAllExpenses()
            let calendar = Calendar.current
            let now = Date()

            // Apply multiple filters in sequence
            var result = expenses

            // Date filter
            if let dateRange = DateRangeFilter.last30Days.dateRange() {
                result = result.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
            }

            // Category filter
            result = result.filter { ["Food", "Transportation"].contains($0.category.name) }

            // Amount filter
            result = result.filter { $0.amount >= 10 && $0.amount <= 100 }

            // Sort
            result = result.sorted { $0.date > $1.date }

            // Group by month
            _ = Dictionary(grouping: result) { expense in
                calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
            }
        }
    }

    func testStress_ChartDataGeneration() {
        createExpenses(count: 500)

        measure {
            let expenses = fetchAllExpenses()
            let calendar = Calendar.current
            let now = Date()

            // Generate 12 months of chart data
            let monthsToShow = (0..<12).compactMap { monthOffset in
                calendar.date(byAdding: .month, value: -monthOffset, to: now)
            }

            let groupedByMonth = Dictionary(grouping: expenses) { expense in
                calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
            }

            _ = monthsToShow.map { month in
                let monthStart = calendar.dateInterval(of: .month, for: month)?.start ?? month
                let monthExpenses = groupedByMonth[monthStart] ?? []
                let total = monthExpenses.reduce(Decimal.zero) { $0 + $1.amount }
                return (month: month, total: total)
            }
        }
    }

    func testStress_CategoryBreakdownCalculation() {
        createExpenses(count: 500)

        measure {
            let expenses = fetchAllExpenses()
            let total = expenses.reduce(Decimal.zero) { $0 + $1.amount }

            guard total > 0 else { return }

            let groupedByCategory = Dictionary(grouping: expenses) { $0.category.name }

            _ = groupedByCategory.map { (categoryName, categoryExpenses) in
                let categoryTotal = categoryExpenses.reduce(Decimal.zero) { $0 + $1.amount }
                let percentage = Double(truncating: categoryTotal as NSDecimalNumber) /
                    Double(truncating: total as NSDecimalNumber) * 100
                return (category: categoryName, total: categoryTotal, percentage: percentage)
            }.sorted { $0.total > $1.total }
        }
    }

    // MARK: - Memory Tests

    func testMemory_LargeDatasetAllocation() {
        // Test memory usage with 1000 expenses
        let count = 1000
        createExpenses(count: count)

        let expenses = fetchAllExpenses()
        XCTAssertEqual(expenses.count, count, "Should have all expenses in memory")

        // Perform operations on the dataset
        let total = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        XCTAssertGreaterThan(total, 0)

        let sorted = expenses.sorted { $0.date > $1.date }
        XCTAssertEqual(sorted.count, count)

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) { expense in
            calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        }
        XCTAssertGreaterThan(grouped.keys.count, 0)
    }

    // MARK: - Validation Tests

    func testDataIntegrity_LargeDataset() {
        let count = 500
        createExpenses(count: count)

        let expenses = fetchAllExpenses()
        XCTAssertEqual(expenses.count, count, "Should fetch exact number of expenses")

        // Verify all expenses have valid data
        for expense in expenses {
            XCTAssertGreaterThan(expense.amount, 0, "All amounts should be positive")
            XCTAssertNotNil(expense.category, "All expenses should have a category")
            XCTAssertNotNil(expense.date, "All expenses should have a date")
        }
    }

    func testConcurrentRead_LargeDataset() {
        createExpenses(count: 500)

        let expectation = XCTestExpectation(description: "Concurrent reads")
        expectation.expectedFulfillmentCount = 5

        // Simulate multiple concurrent read operations with separate contexts per thread
        for _ in 0..<5 {
            DispatchQueue.global().async {
                // Create a separate context for this thread (ModelContext is not thread-safe)
                let threadContext = ModelContext(self.modelContainer)

                let fetchDescriptor = FetchDescriptor<ExpenseTracker.Expense>()
                do {
                    let expenses = try threadContext.fetch(fetchDescriptor)
                    XCTAssertGreaterThan(expenses.count, 0)
                } catch {
                    XCTFail("Failed to fetch expenses: \(error)")
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Helper Methods

    private func createExpenses(count: Int) {
        let calendar = Calendar.current
        let now = Date()

        for i in 0..<count {
            // Distribute expenses across last 12 months
            let daysBack = Int.random(in: 0...(365))
            guard let date = calendar.date(byAdding: .day, value: -daysBack, to: now) else { continue }

            // Random amount between $5 and $500
            let amount = Decimal(Double.random(in: 5...500))

            // Random category
            let category = testCategories.randomElement()!

            let expense = ExpenseTracker.Expense(
                amount: amount,
                date: date,
                notes: "Test expense \(i)",
                category: category
            )
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
        }
    }

    private func fetchAllExpenses() -> [ExpenseTracker.Expense] {
        let fetchDescriptor = FetchDescriptor<ExpenseTracker.Expense>()
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            XCTFail("Failed to fetch expenses: \(error)")
            return []
        }
    }
}
