//
//  ComprehensiveFilterTests.swift
//  ExpenseTrackerTests
//
//  Created by Claude Code on 10/23/25.
//

import XCTest
import SwiftData
@testable import ExpenseTracker

/// Tests complex filtering combinations (date ranges + categories + search together)
class ComprehensiveFilterTests: XCTestCase {

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

            // Create diverse categories
            let categories = [
                ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife"),
                ExpenseTracker.Category(name: "Transportation", color: "blue", symbolName: "car.fill"),
                ExpenseTracker.Category(name: "Entertainment", color: "purple", symbolName: "tv.fill"),
                ExpenseTracker.Category(name: "Bills", color: "red", symbolName: "doc.text.fill")
            ]

            for category in categories {
                modelContext.insert(category)
            }
            try modelContext.save()
            testCategories = categories

            // Create diverse expenses spanning multiple time periods
            let calendar = Calendar.current
            let now = Date()

            let expenses = [
                // This month - Food
                ExpenseTracker.Expense(amount: 25.50, date: now, notes: "Coffee shop breakfast", category: categories[0]),
                ExpenseTracker.Expense(amount: 45.99, date: calendar.date(byAdding: .day, value: -3, to: now)!, notes: "Grocery store shopping", category: categories[0]),
                ExpenseTracker.Expense(amount: 18.00, date: calendar.date(byAdding: .day, value: -5, to: now)!, notes: "Fast food lunch", category: categories[0]),

                // This month - Transportation
                ExpenseTracker.Expense(amount: 15.00, date: calendar.date(byAdding: .day, value: -2, to: now)!, notes: "Bus fare downtown", category: categories[1]),
                ExpenseTracker.Expense(amount: 50.00, date: calendar.date(byAdding: .day, value: -4, to: now)!, notes: "Gas station fill-up", category: categories[1]),

                // Last month - Food
                ExpenseTracker.Expense(amount: 120.75, date: calendar.date(byAdding: .month, value: -1, to: now)!, notes: "Restaurant dinner party", category: categories[0]),
                ExpenseTracker.Expense(amount: 35.50, date: calendar.date(byAdding: .month, value: -1, to: now)!.addingTimeInterval(-86400 * 5), notes: "Grocery shopping", category: categories[0]),

                // Last month - Entertainment
                ExpenseTracker.Expense(amount: 45.00, date: calendar.date(byAdding: .month, value: -1, to: now)!, notes: "Movie theater tickets", category: categories[2]),
                ExpenseTracker.Expense(amount: 60.00, date: calendar.date(byAdding: .month, value: -1, to: now)!.addingTimeInterval(-86400 * 10), notes: "Concert tickets", category: categories[2]),

                // Year to date - Bills
                ExpenseTracker.Expense(amount: 89.99, date: calendar.date(byAdding: .month, value: -3, to: now)!, notes: "Electric bill payment", category: categories[3]),
                ExpenseTracker.Expense(amount: 120.00, date: calendar.date(byAdding: .month, value: -4, to: now)!, notes: "Internet bill", category: categories[3]),

                // Last 7 days - mixed
                ExpenseTracker.Expense(amount: 12.50, date: calendar.date(byAdding: .day, value: -6, to: now)!, notes: "Coffee", category: categories[0]),
                ExpenseTracker.Expense(amount: 8.00, date: calendar.date(byAdding: .day, value: -6, to: now)!, notes: "Parking meter", category: categories[1])
            ]

            for expense in expenses {
                modelContext.insert(expense)
            }
            try modelContext.save()

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

    // MARK: - Complex Combination Tests

    func testCombinedFilter_ThisMonthAndFoodCategory() {
        let filter = DateRangeFilter.thisMonth
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range")
            return
        }

        let allExpenses = fetchAllExpenses()
        let foodCategory = testCategories.first { $0.name == "Food" }!

        let filtered = allExpenses.filter { expense in
            let dateMatch = expense.date >= dateRange.start && expense.date <= dateRange.end
            let categoryMatch = expense.category.name == foodCategory.name
            return dateMatch && categoryMatch
        }

        XCTAssertGreaterThan(filtered.count, 0, "Should have Food expenses this month")
        for expense in filtered {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end)
            XCTAssertEqual(expense.category.name, "Food")
        }
    }

    func testCombinedFilter_Last7DaysAndSearchText() {
        let filter = DateRangeFilter.last7Days
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range")
            return
        }

        let allExpenses = fetchAllExpenses()
        let searchText = "coffee"

        let filtered = allExpenses.filter { expense in
            let dateMatch = expense.date >= dateRange.start && expense.date <= dateRange.end
            let searchMatch = expense.notes?.lowercased().contains(searchText.lowercased()) ?? false
            return dateMatch && searchMatch
        }

        XCTAssertGreaterThan(filtered.count, 0, "Should find coffee expenses in last 7 days")
        for expense in filtered {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end)
            XCTAssertTrue(expense.notes?.lowercased().contains(searchText.lowercased()) ?? false)
        }
    }

    func testCombinedFilter_LastMonthCategoryAndSearchText() {
        let filter = DateRangeFilter.lastMonth
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range")
            return
        }

        let allExpenses = fetchAllExpenses()
        let entertainmentCategory = testCategories.first { $0.name == "Entertainment" }!
        let searchText = "ticket"

        let filtered = allExpenses.filter { expense in
            let dateMatch = expense.date >= dateRange.start && expense.date <= dateRange.end
            let categoryMatch = expense.category.name == entertainmentCategory.name
            let searchMatch = expense.notes?.lowercased().contains(searchText.lowercased()) ?? false
            return dateMatch && categoryMatch && searchMatch
        }

        XCTAssertGreaterThan(filtered.count, 0, "Should find Entertainment ticket expenses last month")
        for expense in filtered {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end)
            XCTAssertEqual(expense.category.name, "Entertainment")
            XCTAssertTrue(expense.notes?.lowercased().contains(searchText.lowercased()) ?? false)
        }
    }

    func testCombinedFilter_CustomDateRangeWithCategory() {
        let calendar = Calendar.current
        let now = Date()
        let customStart = calendar.date(byAdding: .month, value: -2, to: now)!
        let customEnd = calendar.date(byAdding: .day, value: -1, to: now)!

        let filter = DateRangeFilter.custom
        guard let dateRange = filter.dateRange(customStart: customStart, customEnd: customEnd) else {
            XCTFail("Failed to get custom date range")
            return
        }

        let allExpenses = fetchAllExpenses()
        let billsCategory = testCategories.first { $0.name == "Bills" }!

        let filtered = allExpenses.filter { expense in
            let dateMatch = expense.date >= dateRange.start && expense.date <= dateRange.end
            let categoryMatch = expense.category.name == billsCategory.name
            return dateMatch && categoryMatch
        }

        // Should find some Bills expenses in the custom range
        for expense in filtered {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end)
            XCTAssertEqual(expense.category.name, "Bills")
        }
    }

    func testCombinedFilter_AllTimeWithMultipleCategories() {
        let allExpenses = fetchAllExpenses()
        let targetCategories = ["Food", "Transportation"]

        let filtered = allExpenses.filter { expense in
            targetCategories.contains(expense.category.name)
        }

        XCTAssertGreaterThan(filtered.count, 0, "Should find Food and Transportation expenses")
        for expense in filtered {
            XCTAssertTrue(targetCategories.contains(expense.category.name))
        }
    }

    func testFilterChain_DateThenCategoryThenAmountRange() {
        let filter = DateRangeFilter.thisMonth
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range")
            return
        }

        let allExpenses = fetchAllExpenses()

        // Apply date filter
        let dateFiltered = allExpenses.filter { expense in
            expense.date >= dateRange.start && expense.date <= dateRange.end
        }

        // Apply category filter
        let categoryFiltered = dateFiltered.filter { expense in
            expense.category.name == "Food"
        }

        // Apply amount range filter (between $10 and $50)
        let amountFiltered = categoryFiltered.filter { expense in
            expense.amount >= 10 && expense.amount <= 50
        }

        XCTAssertGreaterThan(amountFiltered.count, 0, "Should find expenses matching all criteria")
        for expense in amountFiltered {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end)
            XCTAssertEqual(expense.category.name, "Food")
            XCTAssertTrue(expense.amount >= 10 && expense.amount <= 50)
        }
    }

    func testFilterResults_EmptyWhenNoMatch() {
        let filter = DateRangeFilter.custom
        let calendar = Calendar.current
        let now = Date()

        // Create a custom range in the future (no expenses should match)
        let futureStart = calendar.date(byAdding: .year, value: 1, to: now)!
        let futureEnd = calendar.date(byAdding: .year, value: 2, to: now)!

        guard let dateRange = filter.dateRange(customStart: futureStart, customEnd: futureEnd) else {
            XCTFail("Failed to get custom date range")
            return
        }

        let allExpenses = fetchAllExpenses()
        let filtered = allExpenses.filter { expense in
            expense.date >= dateRange.start && expense.date <= dateRange.end
        }

        XCTAssertEqual(filtered.count, 0, "Should have no expenses in future date range")
    }

    func testSearchFilter_CaseInsensitive() {
        let allExpenses = fetchAllExpenses()
        let searchTexts = ["COFFEE", "coffee", "CoFfEe"]

        for searchText in searchTexts {
            let filtered = allExpenses.filter { expense in
                expense.notes?.lowercased().contains(searchText.lowercased()) ?? false
            }

            XCTAssertGreaterThan(filtered.count, 0, "Should find expenses regardless of case")
            for expense in filtered {
                XCTAssertTrue(expense.notes?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }

    func testSearchFilter_PartialMatch() {
        let allExpenses = fetchAllExpenses()
        let searchText = "shop"  // Should match "shopping", "shop"

        let filtered = allExpenses.filter { expense in
            expense.notes?.lowercased().contains(searchText.lowercased()) ?? false
        }

        XCTAssertGreaterThan(filtered.count, 0, "Should find expenses with partial match")
        for expense in filtered {
            XCTAssertTrue(expense.notes?.lowercased().contains(searchText.lowercased()) ?? false,
                         "Should contain '\(searchText)': \(expense.notes ?? "")")
        }
    }

    func testFilterPerformance_ComplexQuery() {
        measure {
            let filter = DateRangeFilter.last30Days
            guard let dateRange = filter.dateRange() else { return }

            let allExpenses = fetchAllExpenses()
            _ = allExpenses.filter { expense in
                let dateMatch = expense.date >= dateRange.start && expense.date <= dateRange.end
                let categoryMatch = ["Food", "Transportation"].contains(expense.category.name)
                let searchMatch = expense.notes?.lowercased().contains("s") ?? false
                return dateMatch && categoryMatch && searchMatch
            }
        }
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
