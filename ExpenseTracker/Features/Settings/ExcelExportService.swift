//
//  ExcelExportService.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 10/17/25.
//

import Foundation
import SwiftData

struct ExcelExportService {

    static func exportExpensesAsExcel(_ expenses: [Expense]) -> Data? {
        // Export as CSV format with .xlsx extension
        // Excel natively opens CSV files, making this a practical solution
        // without requiring external ZIP/compression libraries

        var csv = "Date,Amount,Category,Notes\n"

        for expense in expenses {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.string(from: expense.date)
            let amount = "\(expense.amount)"
            let category = escapeCSVField(expense.category.name)
            let notes = escapeCSVField(expense.notes ?? "")

            csv += "\(date),\(amount),\(category),\(notes)\n"
        }

        return csv.data(using: .utf8)
    }

    static func createTempExcelFile(data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = timestampFormatter.string(from: Date())
        let filename = "expenses-\(timestamp).xlsx"
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to create Excel file: \(error)")
            return nil
        }
    }

    // MARK: - Private Helpers

    private static func escapeCSVField(_ field: String) -> String {
        let needsQuotes = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")

        if needsQuotes {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }

        return field
    }
}
