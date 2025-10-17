//
//  CSVService.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/30/25.
//

import Foundation
import SwiftData

struct CSVService {

    // MARK: - Export

    static func exportExpenses(_ expenses: [Expense]) -> String {
        var csv = "date,amount,category,notes\n"

        for expense in expenses {
            let date = importDateFormatter.string(from: expense.date)
            let amount = "\(expense.amount)"
            let category = expense.category.name
            let notes = escapeCSVField(expense.notes ?? "")

            csv += "\(date),\(amount),\(category),\(notes)\n"
        }

        return csv
    }

    static func createTempCSVFile(content: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = timestampFormatter.string(from: Date())
        let filename = "expenses-\(timestamp).csv"
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to create CSV file: \(error)")
            return nil
        }
    }

    // MARK: - Import

    struct ImportResult {
        let imported: Int
        let duplicatesSkipped: Int
        let invalidRows: Int
        let errors: [String]
    }

    static func importCSV(
        from url: URL,
        into modelContext: ModelContext,
        existingExpenses: [Expense],
        existingCategories: [Category]
    ) -> ImportResult {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return parseCSVContent(
                content,
                modelContext: modelContext,
                existingExpenses: existingExpenses,
                existingCategories: existingCategories
            )
        } catch {
            return ImportResult(
                imported: 0,
                duplicatesSkipped: 0,
                invalidRows: 1,
                errors: ["Failed to read file: \(error.localizedDescription)"]
            )
        }
    }

    private static func parseCSVContent(
        _ content: String,
        modelContext: ModelContext,
        existingExpenses: [Expense],
        existingCategories: [Category]
    ) -> ImportResult {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            return ImportResult(
                imported: 0,
                duplicatesSkipped: 0,
                invalidRows: 1,
                errors: ["Empty or invalid CSV file"]
            )
        }

        // Skip header row
        let dataLines = Array(lines.dropFirst())

        var imported = 0
        var duplicatesSkipped = 0
        var invalidRows = 0
        var errors: [String] = []
        var categories = existingCategories

        for (index, line) in dataLines.enumerated() {
            let lineNumber = index + 2 // +2 because we skip header and arrays are 0-indexed

            let result = processDataLine(
                line: line,
                lineNumber: lineNumber,
                modelContext: modelContext,
                existingExpenses: existingExpenses,
                categories: &categories
            )

            imported += result.importedDelta
            duplicatesSkipped += result.duplicatesDelta
            invalidRows += result.invalidDelta
            errors.append(contentsOf: result.errors)
        }

        // Save changes
        do {
            try modelContext.save()
        } catch {
            errors.append("Failed to save imported expenses: \(error.localizedDescription)")
        }

        return ImportResult(
            imported: imported,
            duplicatesSkipped: duplicatesSkipped,
            invalidRows: invalidRows,
            errors: errors
        )
    }

    // MARK: - Helper Functions

    private struct ProcessResult {
        var importedDelta: Int
        var duplicatesDelta: Int
        var invalidDelta: Int
        var errors: [String]
    }

    private static let importDateFormatter: DateFormatter = {
        let dateFormatterInstance = DateFormatter()
        dateFormatterInstance.dateFormat = "yyyy-MM-dd"
        return dateFormatterInstance
    }()

    private static func processDataLine(
        line: String,
        lineNumber: Int,
        modelContext: ModelContext,
        existingExpenses: [Expense],
        categories: inout [Category]
    ) -> ProcessResult {
        var result = ProcessResult(importedDelta: 0, duplicatesDelta: 0, invalidDelta: 0, errors: [])

        let fields = parseCSVLine(line)
        guard fields.count >= 3 else {
            result.invalidDelta += 1
            result.errors.append("Line \(lineNumber): Not enough fields")
            return result
        }

        // Parse date
        guard let date = importDateFormatter.date(from: fields[0]) else {
            result.invalidDelta += 1
            result.errors.append("Line \(lineNumber): Invalid date format '\(fields[0])'")
            return result
        }

        // Parse amount
        guard let amount = Decimal(string: fields[1]), amount > 0 else {
            result.invalidDelta += 1
            result.errors.append("Line \(lineNumber): Invalid amount '\(fields[1])'")
            return result
        }

        // Get or create category
        let categoryName = fields[2]
        guard let finalCategory = getOrCreateCategory(
            name: categoryName,
            modelContext: modelContext,
            categories: &categories
        ) else {
            result.invalidDelta += 1
            result.errors.append("Line \(lineNumber): Failed to create category '\(categoryName)'")
            return result
        }

        // Get notes (field 4 if present)
        let notes = fields.count > 3 && !fields[3].isEmpty ? fields[3] : nil

        // Check for duplicates
        if isDuplicateExpense(
            existingExpenses: existingExpenses,
            date: date,
            amount: amount,
            notes: notes,
            categoryName: categoryName
        ) {
            result.duplicatesDelta += 1
            return result
        }

        // Create and insert expense
        let expense = Expense(amount: amount, date: date, notes: notes, category: finalCategory)
        modelContext.insert(expense)
        result.importedDelta += 1

        return result
    }

    private static func getOrCreateCategory(
        name: String,
        modelContext: ModelContext,
        categories: inout [Category]
    ) -> Category? {
        if let existing = categories.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existing
        }

        let newCategory = Category(name: name, color: "gray", symbolName: "square.grid.2x2.fill")
        modelContext.insert(newCategory)
        categories.append(newCategory)
        return newCategory
    }

    private static func isDuplicateExpense(
        existingExpenses: [Expense],
        date: Date,
        amount: Decimal,
        notes: String?,
        categoryName: String
    ) -> Bool {
        let normalizedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return existingExpenses.contains { expense in
            let expenseNormalizedNotes = expense.notes?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            return Calendar.current.isDate(expense.date, inSameDayAs: date)
                && expense.amount == amount
                && expenseNormalizedNotes == normalizedNotes
                && expense.category.name.lowercased() == categoryName.lowercased()
        }
    }

    private static func escapeCSVField(_ field: String) -> String {
        let needsQuotes = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")

        if needsQuotes {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }

        return field
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var charIndex = line.startIndex

        while charIndex < line.endIndex {
            let char = line[charIndex]

            if char == "\"" {
                let nextIndex = line.index(after: charIndex)
                if insideQuotes && nextIndex < line.endIndex && line[nextIndex] == "\"" {
                    // Escaped quote
                    currentField += "\""
                    charIndex = line.index(after: nextIndex)
                } else {
                    // Toggle quote state
                    insideQuotes.toggle()
                    charIndex = nextIndex
                }
            } else if char == "," && !insideQuotes {
                // Field separator
                fields.append(currentField)
                currentField = ""
                charIndex = line.index(after: charIndex)
            } else {
                currentField += String(char)
                charIndex = line.index(after: charIndex)
            }
        }

        // Add the last field
        fields.append(currentField)

        return fields
    }

    // MARK: - JSON Export

    static func exportExpensesAsJSON(_ expenses: [Expense]) -> String {
        var jsonArray: [[String: Any]] = []

        for expense in expenses {
            let dateString = importDateFormatter.string(from: expense.date)
            let jsonObject: [String: Any] = [
                "date": dateString,
                "amount": expense.amount.description,
                "category": expense.category.name,
                "notes": expense.notes ?? ""
            ]
            jsonArray.append(jsonObject)
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted, .sortedKeys])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("Failed to serialize JSON: \(error)")
        }

        return "[]"
    }

    static func createTempJSONFile(content: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = timestampFormatter.string(from: Date())
        let filename = "expenses-\(timestamp).json"
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to create JSON file: \(error)")
            return nil
        }
    }
}

extension DateFormatter {
    func apply(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}
