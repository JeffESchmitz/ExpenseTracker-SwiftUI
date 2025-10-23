//
//  CSVServiceTests.swift
//  ExpenseTrackerTests
//
//  Created by Claude Code on 10/23/25.
//

import XCTest
import SwiftData
@testable import ExpenseTracker

/// Tests CSV import/export validation and edge cases
class CSVServiceTests: XCTestCase {

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
                ExpenseTracker.Category(name: "Transportation", color: "blue", symbolName: "car.fill")
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

    // MARK: - CSV Export Tests

    func testCSVExport_BasicExpenses() {
        let expenses = [
            ExpenseTracker.Expense(amount: 25.50, date: Date(), notes: "Lunch", category: testCategories[0]),
            ExpenseTracker.Expense(amount: 15.00, date: Date(), notes: "Bus fare", category: testCategories[1])
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

        let csv = CSVService.exportExpenses(expenses)

        // Verify header
        XCTAssertTrue(csv.contains("date,amount,category,notes"), "Should contain CSV header")

        // Verify data rows
        XCTAssertTrue(csv.contains("25.5"), "Should contain first expense amount")
        XCTAssertTrue(csv.contains("15"), "Should contain second expense amount")
        XCTAssertTrue(csv.contains("Food"), "Should contain Food category")
        XCTAssertTrue(csv.contains("Transportation"), "Should contain Transportation category")
        XCTAssertTrue(csv.contains("Lunch"), "Should contain Lunch notes")
        XCTAssertTrue(csv.contains("Bus fare"), "Should contain Bus fare notes")
    }

    func testCSVExport_EmptyExpenses() {
        let csv = CSVService.exportExpenses([])

        // Should only contain header
        XCTAssertEqual(csv, "date,amount,category,notes\n", "Empty export should only contain header")
    }

    func testCSVExport_ExpensesWithoutNotes() {
        let expense = ExpenseTracker.Expense(amount: 50.00, date: Date(), notes: nil, category: testCategories[0])
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        let csv = CSVService.exportExpenses([expense])

        XCTAssertTrue(csv.contains("date,amount,category,notes"), "Should contain header")
        XCTAssertTrue(csv.contains("50"), "Should contain amount")
        XCTAssertTrue(csv.contains("Food"), "Should contain category")
    }

    func testCSVExport_ExpensesWithCommasInNotes() {
        let expense = ExpenseTracker.Expense(
            amount: 50.00,
            date: Date(),
            notes: "Lunch, dinner, and snacks",
            category: testCategories[0]
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        let csv = CSVService.exportExpenses([expense])

        // Notes with commas should be quoted
        XCTAssertTrue(csv.contains("\"Lunch, dinner, and snacks\""),
                     "Notes with commas should be properly escaped")
    }

    func testCSVExport_ExpensesWithQuotesInNotes() {
        let expense = ExpenseTracker.Expense(
            amount: 50.00,
            date: Date(),
            notes: "Lunch at \"Best Restaurant\"",
            category: testCategories[0]
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        let csv = CSVService.exportExpenses([expense])

        // Quotes should be escaped as double quotes
        XCTAssertTrue(csv.contains("\"\"Best Restaurant\"\""),
                     "Quotes should be properly escaped")
    }

    func testCSVExport_ExpensesWithNewlinesInNotes() {
        let expense = ExpenseTracker.Expense(
            amount: 50.00,
            date: Date(),
            notes: "Line 1\nLine 2",
            category: testCategories[0]
        )
        modelContext.insert(expense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save expense: \(error)")
            return
        }

        let csv = CSVService.exportExpenses([expense])

        // Notes with newlines should be quoted
        XCTAssertTrue(csv.contains("\"Line 1\nLine 2\""),
                     "Notes with newlines should be properly escaped")
    }

    func testCSVExport_FileCreation() {
        let expense = ExpenseTracker.Expense(amount: 25.50, date: Date(), notes: "Test", category: testCategories[0])
        let csv = CSVService.exportExpenses([expense])

        let fileURL = CSVService.createTempCSVFile(content: csv)

        XCTAssertNotNil(fileURL, "Should create temp file")

        if let url = fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "File should exist")
            XCTAssertTrue(url.lastPathComponent.hasPrefix("expenses-"), "Filename should start with 'expenses-'")
            XCTAssertTrue(url.lastPathComponent.hasSuffix(".csv"), "Filename should end with '.csv'")

            // Clean up
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - CSV Import Tests

    func testCSVImport_ValidCSV() {
        let csvContent = """
        date,amount,category,notes
        2025-10-23,50.00,Food,Lunch at cafe
        2025-10-22,25.00,Transportation,Bus fare
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 2, "Should import 2 expenses")
        XCTAssertEqual(result.duplicatesSkipped, 0, "Should skip 0 duplicates")
        XCTAssertEqual(result.invalidRows, 0, "Should have 0 invalid rows")
        XCTAssertTrue(result.errors.isEmpty, "Should have no errors")

        let expenses = fetchAllExpenses()
        XCTAssertEqual(expenses.count, 2, "Should have 2 expenses in database")
    }

    func testCSVImport_EmptyFile() {
        let csvContent = ""

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 0)
        XCTAssertEqual(result.invalidRows, 1)
        XCTAssertFalse(result.errors.isEmpty, "Should have error for empty file")
    }

    func testCSVImport_OnlyHeader() {
        let csvContent = "date,amount,category,notes\n"

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 0, "Should import 0 expenses")
        XCTAssertEqual(result.invalidRows, 1, "Should have 1 invalid row (header only)")
    }

    func testCSVImport_InvalidDateFormat() {
        let csvContent = """
        date,amount,category,notes
        10/23/2025,50.00,Food,Lunch
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 0, "Should import 0 expenses")
        XCTAssertEqual(result.invalidRows, 1, "Should have 1 invalid row")
        XCTAssertFalse(result.errors.isEmpty, "Should have error for invalid date")
    }

    func testCSVImport_InvalidAmount() {
        let csvContent = """
        date,amount,category,notes
        2025-10-23,invalid,Food,Lunch
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 0, "Should import 0 expenses")
        XCTAssertEqual(result.invalidRows, 1, "Should have 1 invalid row")
        XCTAssertFalse(result.errors.isEmpty, "Should have error for invalid amount")
    }

    func testCSVImport_NegativeAmount() {
        let csvContent = """
        date,amount,category,notes
        2025-10-23,-50.00,Food,Lunch
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 0, "Should import 0 expenses (negative amounts not allowed)")
        XCTAssertEqual(result.invalidRows, 1, "Should have 1 invalid row")
    }

    func testCSVImport_ZeroAmount() {
        let csvContent = """
        date,amount,category,notes
        2025-10-23,0.00,Food,Lunch
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 0, "Should import 0 expenses (zero amounts not allowed)")
        XCTAssertEqual(result.invalidRows, 1, "Should have 1 invalid row")
    }

    func testCSVImport_MissingFields() {
        let csvContent = """
        date,amount,category,notes
        2025-10-23,50.00
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 0, "Should import 0 expenses")
        XCTAssertEqual(result.invalidRows, 1, "Should have 1 invalid row")
        XCTAssertFalse(result.errors.isEmpty, "Should have error for missing fields")
    }

    func testCSVImport_NewCategoryCreation() {
        let csvContent = """
        date,amount,category,notes
        2025-10-23,50.00,NewCategory,Test expense
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 1, "Should import 1 expense")
        XCTAssertEqual(result.invalidRows, 0, "Should have 0 invalid rows")

        let categories = fetchAllCategories()
        XCTAssertTrue(categories.contains { $0.name == "NewCategory" }, "Should create new category")
    }

    func testCSVImport_DuplicateDetection() {
        // Create existing expense
        let existingExpense = ExpenseTracker.Expense(
            amount: 50.00,
            date: Date(),
            notes: "Lunch",
            category: testCategories[0]
        )
        modelContext.insert(existingExpense)

        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save existing expense: \(error)")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        let csvContent = """
        date,amount,category,notes
        \(dateString),50.00,Food,Lunch
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let existingExpenses = fetchAllExpenses()

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: existingExpenses,
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 0, "Should import 0 expenses")
        XCTAssertEqual(result.duplicatesSkipped, 1, "Should skip 1 duplicate")
        XCTAssertEqual(result.invalidRows, 0, "Should have 0 invalid rows")
    }

    func testCSVImport_MixedValidAndInvalid() {
        let csvContent = """
        date,amount,category,notes
        2025-10-23,50.00,Food,Valid expense
        invalid-date,25.00,Transportation,Invalid date
        2025-10-22,30.00,Food,Another valid expense
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 2, "Should import 2 valid expenses")
        XCTAssertEqual(result.invalidRows, 1, "Should have 1 invalid row")
        XCTAssertFalse(result.errors.isEmpty, "Should have error for invalid row")
    }

    func testCSVImport_QuotedFields() {
        let csvContent = """
        date,amount,category,notes
        2025-10-23,50.00,Food,"Lunch, dinner, snacks"
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 1, "Should import 1 expense")
        XCTAssertEqual(result.invalidRows, 0, "Should have 0 invalid rows")

        let expenses = fetchAllExpenses()
        XCTAssertEqual(expenses.first?.notes, "Lunch, dinner, snacks", "Should preserve notes with commas")
    }

    func testCSVImport_EmptyNotes() {
        let csvContent = """
        date,amount,category,notes
        2025-10-23,50.00,Food,
        """

        let tempURL = createTempFile(content: csvContent)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = CSVService.importCSV(
            from: tempURL,
            into: modelContext,
            existingExpenses: [],
            existingCategories: testCategories
        )

        XCTAssertEqual(result.imported, 1, "Should import 1 expense")

        let expenses = fetchAllExpenses()
        XCTAssertNil(expenses.first?.notes, "Empty notes should be nil")
    }

    // MARK: - JSON Export Tests

    func testJSONExport_BasicExpenses() {
        let expenses = [
            ExpenseTracker.Expense(amount: 25.50, date: Date(), notes: "Lunch", category: testCategories[0]),
            ExpenseTracker.Expense(amount: 15.00, date: Date(), notes: "Bus fare", category: testCategories[1])
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

        let json = CSVService.exportExpensesAsJSON(expenses)

        XCTAssertTrue(json.contains("\"amount\""), "Should contain amount field")
        XCTAssertTrue(json.contains("\"category\""), "Should contain category field")
        XCTAssertTrue(json.contains("\"date\""), "Should contain date field")
        XCTAssertTrue(json.contains("\"notes\""), "Should contain notes field")
        XCTAssertTrue(json.contains("Food"), "Should contain Food category")
        XCTAssertTrue(json.contains("Transportation"), "Should contain Transportation category")
    }

    func testJSONExport_FileCreation() {
        let expense = ExpenseTracker.Expense(amount: 25.50, date: Date(), notes: "Test", category: testCategories[0])
        let json = CSVService.exportExpensesAsJSON([expense])

        let fileURL = CSVService.createTempJSONFile(content: json)

        XCTAssertNotNil(fileURL, "Should create temp file")

        if let url = fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "File should exist")
            XCTAssertTrue(url.lastPathComponent.hasPrefix("expenses-"), "Filename should start with 'expenses-'")
            XCTAssertTrue(url.lastPathComponent.hasSuffix(".json"), "Filename should end with '.json'")

            // Clean up
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Helper Methods

    private func createTempFile(content: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test-\(UUID().uuidString).csv")

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            XCTFail("Failed to create temp file: \(error)")
            return fileURL
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
