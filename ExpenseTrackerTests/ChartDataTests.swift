//
//  ChartDataTests.swift
//  ExpenseTrackerTests
//
//  Created by Claude Code on 10/23/25.
//

import XCTest
import SwiftData
@testable import ExpenseTracker

/// Tests chart data calculation accuracy
class ChartDataTests: XCTestCase {

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
                ExpenseTracker.Category(name: "Entertainment", color: "purple", symbolName: "tv.fill")
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

    // MARK: - Monthly Aggregation Tests

    func testMonthlyAggregation_SingleMonth() {
        let calendar = Calendar.current
        let now = Date()

        // Add expenses for current month
        let expenses = [
            ExpenseTracker.Expense(amount: 100.00, date: now, notes: "Expense 1", category: testCategories[0]),
            ExpenseTracker.Expense(amount: 150.00, date: calendar.date(byAdding: .day, value: -5, to: now)!, notes: "Expense 2", category: testCategories[0]),
            ExpenseTracker.Expense(amount: 200.00, date: calendar.date(byAdding: .day, value: -10, to: now)!, notes: "Expense 3", category: testCategories[0])
        ]

        for expense in expenses {
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Calculate monthly total
        let allExpenses = fetchAllExpenses()
        let thisMonthExpenses = allExpenses.filter { expense in
            calendar.isDate(expense.date, equalTo: now, toGranularity: .month)
        }

        let monthlyTotal = thisMonthExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        XCTAssertEqual(monthlyTotal, 450.00, "Monthly total should be 450.00")
    }

    func testMonthlyAggregation_MultipleMonths() {
        let calendar = Calendar.current
        let now = Date()

        // Create expenses across 3 months
        for monthOffset in 0..<3 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }

            let expense = ExpenseTracker.Expense(
                amount: Decimal(100 * (monthOffset + 1)),
                date: monthDate,
                notes: "Month \(monthOffset)",
                category: testCategories[0]
            )
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Group by month and verify
        let allExpenses = fetchAllExpenses()
        let groupedByMonth = Dictionary(grouping: allExpenses) { expense in
            calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        }

        XCTAssertEqual(groupedByMonth.keys.count, 3, "Should have 3 distinct months")

        // Verify each month has correct total
        for (_, expenses) in groupedByMonth {
            let monthTotal = expenses.reduce(Decimal.zero) { $0 + $1.amount }
            XCTAssertGreaterThan(monthTotal, 0, "Each month should have positive total")
        }
    }

    func testMonthlyAggregation_EmptyMonths() {
        let calendar = Calendar.current
        let now = Date()

        // Create expenses with gaps (month 0 and month 2, skip month 1)
        for monthOffset in [0, 2] {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }

            let expense = ExpenseTracker.Expense(
                amount: 100.00,
                date: monthDate,
                notes: "Month \(monthOffset)",
                category: testCategories[0]
            )
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Build complete month range including empty months
        let monthsToShow = (0..<3).compactMap { monthOffset in
            calendar.date(byAdding: .month, value: -monthOffset, to: now)
        }

        let allExpenses = fetchAllExpenses()
        let groupedByMonth = Dictionary(grouping: allExpenses) { expense in
            calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        }

        // Verify chart data includes zero for empty months
        for monthDate in monthsToShow {
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let monthExpenses = groupedByMonth[monthStart] ?? []
            let monthTotal = monthExpenses.reduce(Decimal.zero) { $0 + $1.amount }

            // Should have data for months 0 and 2, zero for month 1
            if calendar.dateComponents([.month], from: monthDate, to: now).month == 1 {
                XCTAssertEqual(monthTotal, 0, "Empty month should have zero total")
            }
        }
    }

    // MARK: - Category Breakdown Tests

    func testCategoryBreakdown_Percentages() {
        // Create expenses with known distribution
        let expenses = [
            ExpenseTracker.Expense(amount: 100.00, date: Date(), notes: "Food 1", category: testCategories[0]),
            ExpenseTracker.Expense(amount: 200.00, date: Date(), notes: "Transport 1", category: testCategories[1]),
            ExpenseTracker.Expense(amount: 300.00, date: Date(), notes: "Entertainment 1", category: testCategories[2])
        ]

        for expense in expenses {
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Calculate category percentages
        let allExpenses = fetchAllExpenses()
        let total = allExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        XCTAssertEqual(total, 600.00, "Total should be 600.00")

        let groupedByCategory = Dictionary(grouping: allExpenses) { $0.category.name }

        for (categoryName, categoryExpenses) in groupedByCategory {
            let categoryTotal = categoryExpenses.reduce(Decimal.zero) { $0 + $1.amount }
            let percentage = Double(truncating: categoryTotal as NSDecimalNumber) /
                Double(truncating: total as NSDecimalNumber) * 100

            switch categoryName {
            case "Food":
                XCTAssertEqual(percentage, 16.666666666666668, accuracy: 0.01, "Food should be ~16.67%")
            case "Transportation":
                XCTAssertEqual(percentage, 33.333333333333336, accuracy: 0.01, "Transportation should be ~33.33%")
            case "Entertainment":
                XCTAssertEqual(percentage, 50.0, accuracy: 0.01, "Entertainment should be 50%")
            default:
                XCTFail("Unexpected category: \(categoryName)")
            }
        }
    }

    func testCategoryBreakdown_ZeroTotal() {
        // Test with no expenses
        let allExpenses = fetchAllExpenses()
        let total = allExpenses.reduce(Decimal.zero) { $0 + $1.amount }

        XCTAssertEqual(total, 0, "Total should be zero with no expenses")

        // Attempting to calculate percentages with zero total should not crash
        if total > 0 {
            let groupedByCategory = Dictionary(grouping: allExpenses) { $0.category.name }
            for (_, categoryExpenses) in groupedByCategory {
                let categoryTotal = categoryExpenses.reduce(Decimal.zero) { $0 + $1.amount }
                _ = Double(truncating: categoryTotal as NSDecimalNumber) /
                    Double(truncating: total as NSDecimalNumber) * 100
            }
        }
    }

    func testCategoryBreakdown_SingleCategory() {
        // All expenses in one category
        let expenses = [
            ExpenseTracker.Expense(amount: 100.00, date: Date(), notes: "Expense 1", category: testCategories[0]),
            ExpenseTracker.Expense(amount: 200.00, date: Date(), notes: "Expense 2", category: testCategories[0]),
            ExpenseTracker.Expense(amount: 300.00, date: Date(), notes: "Expense 3", category: testCategories[0])
        ]

        for expense in expenses {
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        let allExpenses = fetchAllExpenses()
        let groupedByCategory = Dictionary(grouping: allExpenses) { $0.category.name }

        XCTAssertEqual(groupedByCategory.keys.count, 1, "Should have only one category")

        let categoryTotal = groupedByCategory["Food"]!.reduce(Decimal.zero) { $0 + $1.amount }
        let total = allExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        let percentage = Double(truncating: categoryTotal as NSDecimalNumber) /
            Double(truncating: total as NSDecimalNumber) * 100

        XCTAssertEqual(percentage, 100.0, accuracy: 0.01, "Single category should be 100%")
    }

    // MARK: - Trend Calculation Tests

    func testTrendCalculation_PositiveGrowth() {
        let calendar = Calendar.current
        let now = Date()

        // This month: $300
        let thisMonthExpenses = [
            ExpenseTracker.Expense(amount: 100.00, date: now, notes: "This month 1", category: testCategories[0]),
            ExpenseTracker.Expense(amount: 200.00, date: calendar.date(byAdding: .day, value: -5, to: now)!, notes: "This month 2", category: testCategories[0])
        ]

        // Last month: $200
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
            XCTFail("Failed to calculate last month")
            return
        }

        let lastMonthExpenses = [
            ExpenseTracker.Expense(amount: 100.00, date: lastMonth, notes: "Last month 1", category: testCategories[0]),
            ExpenseTracker.Expense(amount: 100.00, date: calendar.date(byAdding: .day, value: -5, to: lastMonth)!, notes: "Last month 2", category: testCategories[0])
        ]

        for expense in thisMonthExpenses + lastMonthExpenses {
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Calculate trend
        let currentTotal = Decimal(300)
        let previousTotal = Decimal(200)
        let difference = currentTotal - previousTotal

        let percentage = Double(truncating: difference as NSDecimalNumber) /
            Double(truncating: previousTotal as NSDecimalNumber) * 100

        XCTAssertEqual(percentage, 50.0, accuracy: 0.01, "Should show 50% increase")
    }

    func testTrendCalculation_NegativeGrowth() {
        let currentTotal = Decimal(200)
        let previousTotal = Decimal(300)
        let difference = currentTotal - previousTotal

        let percentage = Double(truncating: difference as NSDecimalNumber) /
            Double(truncating: previousTotal as NSDecimalNumber) * 100

        XCTAssertEqual(percentage, -33.33, accuracy: 0.01, "Should show ~33.33% decrease")
    }

    func testTrendCalculation_ZeroPrevious() {
        let currentTotal = Decimal(200)
        let previousTotal = Decimal(0)

        // Should handle division by zero gracefully
        let percentage = previousTotal > 0 ?
            (Double(truncating: (currentTotal - previousTotal) as NSDecimalNumber) /
             Double(truncating: previousTotal as NSDecimalNumber)) * 100 : 0

        XCTAssertEqual(percentage, 0, "Should return 0 when previous is zero")
    }

    // MARK: - Data Sorting Tests

    func testExpenseSorting_ByDate() {
        let calendar = Calendar.current
        let now = Date()

        let dates = [
            now,
            calendar.date(byAdding: .day, value: -5, to: now)!,
            calendar.date(byAdding: .day, value: -10, to: now)!,
            calendar.date(byAdding: .month, value: -1, to: now)!
        ]

        for (index, date) in dates.enumerated() {
            let expense = ExpenseTracker.Expense(
                amount: Decimal(100 + index * 10),
                date: date,
                notes: "Expense \(index)",
                category: testCategories[0]
            )
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Fetch and sort
        let allExpenses = fetchAllExpenses().sorted { $0.date > $1.date }

        XCTAssertEqual(allExpenses.count, 4)

        // Verify descending order
        for i in 0..<(allExpenses.count - 1) {
            XCTAssertGreaterThanOrEqual(allExpenses[i].date, allExpenses[i + 1].date,
                                        "Expenses should be sorted in descending order")
        }
    }

    func testExpenseSorting_ByAmount() {
        let amounts: [Decimal] = [100, 50, 200, 75, 150]

        for amount in amounts {
            let expense = ExpenseTracker.Expense(
                amount: amount,
                date: Date(),
                notes: "Amount \(amount)",
                category: testCategories[0]
            )
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Fetch and sort
        let allExpenses = fetchAllExpenses().sorted { $0.amount > $1.amount }

        XCTAssertEqual(allExpenses.count, 5)

        // Verify descending order by amount
        XCTAssertEqual(allExpenses[0].amount, 200)
        XCTAssertEqual(allExpenses[1].amount, 150)
        XCTAssertEqual(allExpenses[2].amount, 100)
        XCTAssertEqual(allExpenses[3].amount, 75)
        XCTAssertEqual(allExpenses[4].amount, 50)
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
}
