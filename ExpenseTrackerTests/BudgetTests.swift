//
//  BudgetTests.swift
//  ExpenseTrackerTests
//
//  Created by Jeff E. Schmitz on 10/17/25.
//

import XCTest
@testable import ExpenseTracker

final class BudgetTests: XCTestCase {

    // MARK: - endOfMonth Tests

    func testEndOfMonthIncludesLastDayOfMonth() {
        // Given: A date in the middle of the month
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 10
        components.day = 15
        let midMonthDate = calendar.date(from: components)!

        // When: We get endOfMonth
        let endOfMonth = midMonthDate.endOfMonth

        // Then: It should be in October 2025
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endOfMonth)
        XCTAssertEqual(endComponents.year, 2025)
        XCTAssertEqual(endComponents.month, 10)
        XCTAssertEqual(endComponents.day, 31)

        // And: The time should be 23:59:59 (just before midnight)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: endOfMonth)
        XCTAssertEqual(timeComponents.hour, 23)
        XCTAssertEqual(timeComponents.minute, 59)
        XCTAssertEqual(timeComponents.second, 59)
    }

    func testEndOfMonthForFebruary() {
        // Given: A date in February (non-leap year)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 2
        components.day = 1
        let februaryDate = calendar.date(from: components)!

        // When: We get endOfMonth
        let endOfMonth = februaryDate.endOfMonth

        // Then: It should be February 28
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endOfMonth)
        XCTAssertEqual(endComponents.day, 28)
    }

    // MARK: - calculateCurrentSpending Tests

    func testCalculateCurrentSpendingIncludesExpensesOnLastDay() throws {
        // Given: A category with expenses throughout the month, including on the last day
        let category = try Category(name: "Food", colorHex: "#FF0000")
        let budget = try Budget(category: category, monthlyLimit: 200, currentMonth: Date())

        // Get the month start and end dates
        let calendar = Calendar.current
        let monthStart = Date().startOfMonth
        let monthEnd = Date().endOfMonth

        // Create an expense on the first day
        let firstDayExpense = Expense(
            category: category,
            amount: 50,
            description: "First day",
            date: monthStart,
            isDemo: false
        )

        // Create an expense on the last day (11 PM)
        var lastDayComponents = calendar.dateComponents([.year, .month, .day], from: monthEnd)
        lastDayComponents.hour = 23
        lastDayComponents.minute = 30
        let lastDayDate = calendar.date(from: lastDayComponents)!
        let lastDayExpense = Expense(
            category: category,
            amount: 75,
            description: "Last day",
            date: lastDayDate,
            isDemo: false
        )

        // Add expenses to category
        category.expenses.append(firstDayExpense)
        category.expenses.append(lastDayExpense)

        // When: We calculate current spending
        let spending = budget.calculateCurrentSpending()

        // Then: Both expenses should be included
        XCTAssertEqual(spending, 125)
    }

    func testCalculateCurrentSpendingExcludesExpensesOutsideMonth() throws {
        // Given: A category with expenses in and out of the current month
        let category = try Category(name: "Food", colorHex: "#FF0000")
        let budget = try Budget(category: category, monthlyLimit: 200, currentMonth: Date())

        let calendar = Calendar.current
        let monthStart = Date().startOfMonth

        // Create an expense in the current month
        let currentMonthExpense = Expense(
            category: category,
            amount: 50,
            description: "This month",
            date: monthStart,
            isDemo: false
        )

        // Create an expense next month
        var nextMonthComponents = calendar.dateComponents([.year, .month], from: monthStart)
        nextMonthComponents.month = (nextMonthComponents.month ?? 0) + 1
        nextMonthComponents.day = 1
        let nextMonthDate = calendar.date(from: nextMonthComponents)!
        let nextMonthExpense = Expense(
            category: category,
            amount: 75,
            description: "Next month",
            date: nextMonthDate,
            isDemo: false
        )

        // Add both expenses
        category.expenses.append(currentMonthExpense)
        category.expenses.append(nextMonthExpense)

        // When: We calculate current spending
        let spending = budget.calculateCurrentSpending()

        // Then: Only current month expense should be included
        XCTAssertEqual(spending, 50)
    }
}
