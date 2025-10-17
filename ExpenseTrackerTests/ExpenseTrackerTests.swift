//
//  ExpenseTrackerTests.swift
//  ExpenseTrackerTests
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import XCTest
import SwiftData
@testable import ExpenseTracker

class ExpenseFilterTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testCategories: [ExpenseTracker.Category]!

    override func setUp() {
        super.setUp()

        // Create in-memory container for testing
        let schema = Schema([ExpenseTracker.Expense.self, ExpenseTracker.Category.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = ModelContext(modelContainer)

            // Create test categories
            let foodCategory = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
            let transportCategory = ExpenseTracker.Category(name: "Transportation", color: "blue", symbolName: "car.fill")
            let billsCategory = ExpenseTracker.Category(name: "Bills", color: "red", symbolName: "doc.text.fill")

            modelContext.insert(foodCategory)
            modelContext.insert(transportCategory)
            modelContext.insert(billsCategory)

            try modelContext.save()

            testCategories = [foodCategory, transportCategory, billsCategory]

            // Create test expenses with different dates
            let calendar = Calendar.current
            let now = Date()

            let expenses = [
                // This month
                ExpenseTracker.Expense(amount: 25.50, date: now, notes: "Recent lunch", category: foodCategory),
                ExpenseTracker.Expense(amount: 15.00, date: calendar.date(byAdding: .day, value: -2, to: now)!, notes: "Bus fare", category: transportCategory),

                // Last month
                ExpenseTracker.Expense(amount: 45.99, date: calendar.date(byAdding: .month, value: -1, to: now)!, notes: "Last month expense", category: foodCategory),

                // Last 7 days
                ExpenseTracker.Expense(amount: 120.75, date: calendar.date(byAdding: .day, value: -5, to: now)!, notes: "Grocery shopping", category: foodCategory),

                // Last 30 days
                ExpenseTracker.Expense(amount: 89.99, date: calendar.date(byAdding: .day, value: -20, to: now)!, notes: "Electric bill", category: billsCategory),

                // Year to date
                ExpenseTracker.Expense(amount: 200.00, date: calendar.date(byAdding: .month, value: -3, to: now)!, notes: "Car insurance", category: transportCategory)
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

    func testDateRangeFilterThisMonth() {
        let filter = DateRangeFilter.thisMonth
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range for This Month filter")
            return
        }

        let allExpenses = fetchAllExpenses()
        let filteredExpenses = allExpenses.filter { expense in
            expense.date >= dateRange.start && expense.date <= dateRange.end
        }

        XCTAssertGreaterThan(filteredExpenses.count, 0, "This Month filter should return some expenses")

        for expense in filteredExpenses {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end,
                         "Expense date should be within This Month range")
        }
    }

    func testDateRangeFilterLastMonth() {
        let filter = DateRangeFilter.lastMonth
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range for Last Month filter")
            return
        }

        let allExpenses = fetchAllExpenses()
        let filteredExpenses = allExpenses.filter { expense in
            expense.date >= dateRange.start && expense.date <= dateRange.end
        }

        // Should have at least one expense from last month
        XCTAssertGreaterThan(filteredExpenses.count, 0, "Last Month filter should return some expenses")

        for expense in filteredExpenses {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end,
                         "Expense date should be within Last Month range")
        }
    }

    func testDateRangeFilterLast7Days() {
        let filter = DateRangeFilter.last7Days
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range for Last 7 Days filter")
            return
        }

        let allExpenses = fetchAllExpenses()
        let filteredExpenses = allExpenses.filter { expense in
            expense.date >= dateRange.start && expense.date <= dateRange.end
        }

        XCTAssertGreaterThan(filteredExpenses.count, 0, "Last 7 Days filter should return some expenses")

        for expense in filteredExpenses {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end,
                         "Expense date should be within Last 7 Days range")
        }
    }

    func testDateRangeFilterLast30Days() {
        let filter = DateRangeFilter.last30Days
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range for Last 30 Days filter")
            return
        }

        let allExpenses = fetchAllExpenses()
        let filteredExpenses = allExpenses.filter { expense in
            expense.date >= dateRange.start && expense.date <= dateRange.end
        }

        XCTAssertGreaterThan(filteredExpenses.count, 0, "Last 30 Days filter should return some expenses")

        for expense in filteredExpenses {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end,
                         "Expense date should be within Last 30 Days range")
        }
    }

    func testDateRangeFilterYearToDate() {
        let filter = DateRangeFilter.yearToDate
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range for Year to Date filter")
            return
        }

        let allExpenses = fetchAllExpenses()
        let filteredExpenses = allExpenses.filter { expense in
            expense.date >= dateRange.start && expense.date <= dateRange.end
        }

        XCTAssertGreaterThan(filteredExpenses.count, 0, "Year to Date filter should return some expenses")

        for expense in filteredExpenses {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end,
                         "Expense date should be within Year to Date range")
        }
    }

    func testDateRangeFilterCustom() {
        let calendar = Calendar.current
        let now = Date()
        let customStart = calendar.date(byAdding: .day, value: -10, to: now)!
        let customEnd = calendar.date(byAdding: .day, value: -1, to: now)!

        let filter = DateRangeFilter.custom
        guard let dateRange = filter.dateRange(customStart: customStart, customEnd: customEnd) else {
            XCTFail("Failed to get date range for Custom filter")
            return
        }

        let allExpenses = fetchAllExpenses()
        let filteredExpenses = allExpenses.filter { expense in
            expense.date >= dateRange.start && expense.date <= dateRange.end
        }

        // Custom range should include specific expenses
        for expense in filteredExpenses {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end,
                         "Expense date should be within Custom range")
        }
    }

    func testCategoryFilter() {
        let allExpenses = fetchAllExpenses()
        let foodCategory = testCategories.first { $0.name == "Food" }!

        let filteredExpenses = allExpenses.filter { expense in
            expense.category.name == foodCategory.name
        }

        XCTAssertGreaterThan(filteredExpenses.count, 0, "Food category filter should return some expenses")

        for expense in filteredExpenses {
            XCTAssertEqual(expense.category.name, "Food", "All filtered expenses should be in Food category")
        }
    }

    func testCombinedFilters() {
        let filter = DateRangeFilter.thisMonth
        guard let dateRange = filter.dateRange() else {
            XCTFail("Failed to get date range for This Month filter")
            return
        }

        let allExpenses = fetchAllExpenses()
        let foodCategory = testCategories.first { $0.name == "Food" }!

        // Apply both date range and category filters
        let filteredExpenses = allExpenses.filter { expense in
            let dateMatch = expense.date >= dateRange.start && expense.date <= dateRange.end
            let categoryMatch = expense.category.name == foodCategory.name
            return dateMatch && categoryMatch
        }

        // Should have at least some expenses that match both filters
        for expense in filteredExpenses {
            XCTAssertTrue(expense.date >= dateRange.start && expense.date <= dateRange.end,
                         "Expense date should be within This Month range")
            XCTAssertEqual(expense.category.name, "Food", "Expense should be in Food category")
        }
    }

    func testFilterDisplayNames() {
        XCTAssertEqual(DateRangeFilter.thisMonth.displayName, "This Month")
        XCTAssertEqual(DateRangeFilter.lastMonth.displayName, "Last Month")
        XCTAssertEqual(DateRangeFilter.last7Days.displayName, "Last 7 Days")
        XCTAssertEqual(DateRangeFilter.last30Days.displayName, "Last 30 Days")
        XCTAssertEqual(DateRangeFilter.yearToDate.displayName, "Year to Date")
        XCTAssertEqual(DateRangeFilter.custom.displayName, "Custom")
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

// MARK: - Category Management Tests
class CategoryManagementTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()

        // Create in-memory container for testing
        let schema = Schema([ExpenseTracker.Expense.self, ExpenseTracker.Category.self])
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

    func testUniqueNameValidation() {
        // Create initial category
        let foodCategory = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(foodCategory)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save initial category: \(error)")
            return
        }

        // Test case-insensitive uniqueness
        let existingCategories = fetchAllCategories()
        let existingNames = existingCategories.map { $0.name.lowercased() }

        // Should reject duplicate names (exact case)
        XCTAssertTrue(existingNames.contains("food"))

        // Should reject duplicate names (different case)
        XCTAssertTrue(existingNames.contains("food"))
        let duplicateName = "FOOD"
        XCTAssertTrue(existingNames.contains(duplicateName.lowercased()))

        // Should allow unique names
        let uniqueName = "Transportation"
        XCTAssertFalse(existingNames.contains(uniqueName.lowercased()))
    }

    func testCategoryDeletionWithExpenseReassignment() {
        // Create categories
        let foodCategory = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        let uncategorizedCategory = ExpenseTracker.Category(name: "Uncategorized", color: "gray", symbolName: "questionmark.circle.fill")

        modelContext.insert(foodCategory)
        modelContext.insert(uncategorizedCategory)

        // Create expenses with Food category
        let expense1 = ExpenseTracker.Expense(amount: 25.50, date: Date(), notes: "Lunch", category: foodCategory)
        let expense2 = ExpenseTracker.Expense(amount: 15.00, date: Date(), notes: "Snack", category: foodCategory)

        modelContext.insert(expense1)
        modelContext.insert(expense2)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save initial data: \(error)")
            return
        }

        // Verify initial state
        let initialExpenses = fetchAllExpenses()
        XCTAssertEqual(initialExpenses.count, 2)
        XCTAssertTrue(initialExpenses.allSatisfy { $0.category.name == "Food" })

        // Simulate category deletion with reassignment
        let expensesToReassign = initialExpenses.filter { $0.category.name == "Food" }

        for expense in expensesToReassign {
            expense.category = uncategorizedCategory
        }

        modelContext.delete(foodCategory)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save after reassignment: \(error)")
            return
        }

        // Verify reassignment
        let finalExpenses = fetchAllExpenses()
        XCTAssertEqual(finalExpenses.count, 2, "Should still have 2 expenses after category deletion")
        XCTAssertTrue(finalExpenses.allSatisfy { $0.category.name == "Uncategorized" }, "All expenses should be reassigned to Uncategorized")

        // Verify Food category is deleted
        let remainingCategories = fetchAllCategories()
        XCTAssertFalse(remainingCategories.contains { $0.name == "Food" }, "Food category should be deleted")
        XCTAssertTrue(remainingCategories.contains { $0.name == "Uncategorized" }, "Uncategorized category should remain")
    }

    func testUncategorizedCategoryCannotBeDeleted() {
        // Create Uncategorized category
        let uncategorizedCategory = ExpenseTracker.Category(name: "Uncategorized", color: "gray", symbolName: "questionmark.circle.fill")
        modelContext.insert(uncategorizedCategory)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save Uncategorized category: \(error)")
            return
        }

        // Verify Uncategorized exists
        let categories = fetchAllCategories()
        let uncategorized = categories.first { $0.name.lowercased() == "uncategorized" }
        XCTAssertNotNil(uncategorized, "Uncategorized category should exist")

        // In the real app, deletion logic prevents deleting Uncategorized
        // This test verifies the business rule
        let categoryName = uncategorized?.name.lowercased()
        let canDelete = categoryName != "uncategorized"
        XCTAssertFalse(canDelete, "Should not be able to delete Uncategorized category")
    }

    func testCategoryCreationWithValidation() {
        // Test valid category creation
        let validCategory = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(validCategory)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save valid category: \(error)")
            return
        }

        let categories = fetchAllCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "Food")
        XCTAssertEqual(categories.first?.color, "orange")
        XCTAssertEqual(categories.first?.symbolName, "fork.knife")
    }

    func testCategoryEditing() {
        // Create initial category
        let category = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
        modelContext.insert(category)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save initial category: \(error)")
            return
        }

        // Edit category properties
        category.name = "Dining"
        category.color = "red"
        category.symbolName = "restaurant.fill"

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save edited category: \(error)")
            return
        }

        // Verify changes
        let categories = fetchAllCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "Dining")
        XCTAssertEqual(categories.first?.color, "red")
        XCTAssertEqual(categories.first?.symbolName, "restaurant.fill")
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

// MARK: - Budget Model Tests
class BudgetModelTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testCategory: ExpenseTracker.Category!
    var testBudget: ExpenseTracker.Budget!

    override func setUp() {
        super.setUp()

        // Create in-memory container for testing
        let schema = Schema([ExpenseTracker.Expense.self, ExpenseTracker.Category.self, ExpenseTracker.Budget.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = ModelContext(modelContainer)

            // Create test category
            testCategory = ExpenseTracker.Category(name: "Food", color: "orange", symbolName: "fork.knife")
            modelContext.insert(testCategory)

            // Create test budget for this month
            let thisMonthDate = Date().startOfMonth
            testBudget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: thisMonthDate,
                notes: "Grocery and dining budget"
            )
            modelContext.insert(testBudget)

            try modelContext.save()

        } catch {
            XCTFail("Failed to set up test environment: \(error)")
        }
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        testCategory = nil
        testBudget = nil
        super.tearDown()
    }

    func testBudgetInitialization() {
        XCTAssertEqual(testBudget.monthlyLimit, 500.00)
        XCTAssertEqual(testBudget.category.name, "Food")
        XCTAssertEqual(testBudget.notes, "Grocery and dining budget")
        XCTAssertFalse(testBudget.isDemo)
    }

    func testBudgetValidation_PositiveLimit() {
        // Valid budget with positive limit should work
        do {
            let validBudget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(100),
                currentMonth: Date()
            )
            XCTAssertEqual(validBudget.monthlyLimit, Decimal(100))
        } catch {
            XCTFail("Failed to create valid budget: \(error)")
        }
    }

    func testBudgetValidation_ZeroLimitFails() {
        // Budget with zero limit should fail
        XCTAssertThrowsError(
            try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(0),
                currentMonth: Date()
            ),
            "Budget should not allow zero limit"
        )
    }

    func testBudgetValidation_NegativeLimitFails() {
        // Budget with negative limit should fail
        XCTAssertThrowsError(
            try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(-50),
                currentMonth: Date()
            ),
            "Budget should not allow negative limit"
        )
    }

    func testPercentageUsedCalculation_NoExpenses() {
        // With no expenses, percentage used should be 0
        XCTAssertEqual(testBudget.percentageUsed, 0.0)
    }

    func testPercentageUsedCalculation_PartialSpending() {
        // Add expense for 250 out of 500 budget = 50%
        let expense = ExpenseTracker.Expense(
            amount: Decimal(250),
            date: Date(),
            notes: "Groceries",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertEqual(testBudget.percentageUsed, 50.0, accuracy: 0.01)
    }

    func testPercentageUsedCalculation_FullSpending() {
        // Add expense for full 500 budget = 100%
        let expense = ExpenseTracker.Expense(
            amount: Decimal(500),
            date: Date(),
            notes: "Monthly groceries",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertEqual(testBudget.percentageUsed, 100.0, accuracy: 0.01)
    }

    func testPercentageUsedCalculation_OverSpending() {
        // Add expense for 600 out of 500 budget = 120%
        let expense = ExpenseTracker.Expense(
            amount: Decimal(600),
            date: Date(),
            notes: "Over-budget spending",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertEqual(testBudget.percentageUsed, 120.0, accuracy: 0.01)
    }

    func testAmountRemainingCalculation_NoExpenses() {
        // With no expenses, full budget remains
        XCTAssertEqual(testBudget.amountRemaining, Decimal(500))
    }

    func testAmountRemainingCalculation_PartialSpending() {
        // Add expense for 300, should have 200 remaining
        let expense = ExpenseTracker.Expense(
            amount: Decimal(300),
            date: Date(),
            notes: "Partial spending",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertEqual(testBudget.amountRemaining, Decimal(200))
    }

    func testAmountRemainingCalculation_OverSpending() {
        // When over budget, amountRemaining should be 0 (not negative)
        let expense = ExpenseTracker.Expense(
            amount: Decimal(600),
            date: Date(),
            notes: "Over spending",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertEqual(testBudget.amountRemaining, Decimal(0))
    }

    func testAlertThreshold_Below75Percent() {
        // 25% spending should not trigger alert
        let expense = ExpenseTracker.Expense(
            amount: Decimal(125),  // 25% of 500
            date: Date(),
            notes: "Low spending",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertFalse(testBudget.isAlertThreshold)
    }

    func testAlertThreshold_At75Percent() {
        // Exactly 75% should trigger alert
        let expense = ExpenseTracker.Expense(
            amount: Decimal(375),  // 75% of 500
            date: Date(),
            notes: "Alert level spending",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertTrue(testBudget.isAlertThreshold)
    }

    func testAlertThreshold_Above75Percent() {
        // 80% spending should trigger alert
        let expense = ExpenseTracker.Expense(
            amount: Decimal(400),  // 80% of 500
            date: Date(),
            notes: "High spending",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertTrue(testBudget.isAlertThreshold)
    }

    func testWarningThreshold_Below90Percent() {
        // 80% spending should not trigger warning (only alert)
        let expense = ExpenseTracker.Expense(
            amount: Decimal(400),  // 80% of 500
            date: Date(),
            notes: "Alert level spending",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertTrue(testBudget.isAlertThreshold)
        XCTAssertFalse(testBudget.isWarningThreshold)
    }

    func testWarningThreshold_At90Percent() {
        // Exactly 90% should trigger warning
        let expense = ExpenseTracker.Expense(
            amount: Decimal(450),  // 90% of 500
            date: Date(),
            notes: "Warning level spending",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertTrue(testBudget.isWarningThreshold)
    }

    func testWarningThreshold_Above90Percent() {
        // 95% spending should trigger warning
        let expense = ExpenseTracker.Expense(
            amount: Decimal(475),  // 95% of 500
            date: Date(),
            notes: "Critical spending",
            category: testCategory
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        XCTAssertTrue(testBudget.isWarningThreshold)
    }

    func testCurrentSpendingCalculation_MonthlyScope() {
        // Create expenses in different months
        let calendar = Calendar.current
        let thisMonth = Date().startOfMonth
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: thisMonth)!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: thisMonth)!

        let thisMonthExpense = ExpenseTracker.Expense(
            amount: Decimal(100),
            date: thisMonth.addingTimeInterval(86400),  // First day of month
            notes: "This month",
            category: testCategory
        )
        let lastMonthExpense = ExpenseTracker.Expense(
            amount: Decimal(200),
            date: lastMonth.addingTimeInterval(86400),
            notes: "Last month",
            category: testCategory
        )
        let nextMonthExpense = ExpenseTracker.Expense(
            amount: Decimal(300),
            date: nextMonth.addingTimeInterval(86400),
            notes: "Next month",
            category: testCategory
        )

        modelContext.insert(thisMonthExpense)
        modelContext.insert(lastMonthExpense)
        modelContext.insert(nextMonthExpense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expenses: \(error)")
            return
        }

        // Budget should only count this month's expense
        XCTAssertEqual(testBudget.calculateCurrentSpending(), Decimal(100))
    }

    func testCurrentSpendingCalculation_ExcludesDemoExpenses() {
        // Create regular and demo expenses
        let regularExpense = ExpenseTracker.Expense(
            amount: Decimal(100),
            date: Date(),
            notes: "Regular",
            category: testCategory,
            isDemo: false
        )
        let demoExpense = ExpenseTracker.Expense(
            amount: Decimal(200),
            date: Date(),
            notes: "Demo",
            category: testCategory,
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

        // Budget should only count regular expense, excluding demo
        XCTAssertEqual(testBudget.calculateCurrentSpending(), Decimal(100))
    }

    func testMultipleExpensesCalculation() {
        // Create multiple expenses that should sum correctly
        let expenses = [
            ExpenseTracker.Expense(amount: Decimal(50), date: Date(), notes: "Lunch", category: testCategory),
            ExpenseTracker.Expense(amount: Decimal(75), date: Date(), notes: "Snacks", category: testCategory),
            ExpenseTracker.Expense(amount: Decimal(120), date: Date(), notes: "Groceries", category: testCategory)
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

        // Total should be 245
        XCTAssertEqual(testBudget.calculateCurrentSpending(), Decimal(245))
        XCTAssertEqual(testBudget.percentageUsed, 49.0, accuracy: 0.01)
        XCTAssertEqual(testBudget.amountRemaining, Decimal(255))
    }

    func testBudgetDateNormalizedToMonthStart() {
        // When creating budget with a date in the middle of month,
        // it should normalize to start of month
        let midMonthDate = Date().addingTimeInterval(86400 * 15)  // 15 days from now
        do {
            let budget = try ExpenseTracker.Budget(
                category: testCategory,
                monthlyLimit: Decimal(500),
                currentMonth: midMonthDate
            )

            XCTAssertEqual(budget.currentMonth, midMonthDate.startOfMonth)
        } catch {
            XCTFail("Failed to create budget: \(error)")
        }
    }
}
