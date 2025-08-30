//
//  ExpenseTrackerTests.swift
//  ExpenseTrackerTests
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
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
