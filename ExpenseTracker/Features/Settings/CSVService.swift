//
//  CSVService.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/30/25.
//

import Foundation
import SwiftData

struct CSVService {
    
    // MARK: - Export
    
    static func exportExpenses(_ expenses: [Expense]) -> String {
        var csv = "date,amount,category,notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for expense in expenses {
            let date = dateFormatter.string(from: expense.date)
            let amount = "\(expense.amount)"
            let category = expense.category.name
            let notes = escapeCSVField(expense.notes ?? "")
            
            csv += "\(date),\(amount),\(category),\(notes)\n"
        }
        
        return csv
    }
    
    static func createTempCSVFile(content: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = DateFormatter().apply {
            $0.dateFormat = "yyyy-MM-dd_HH-mm"
        }.string(from: Date())
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
            return ImportResult(imported: 0, duplicatesSkipped: 0, invalidRows: 1, errors: ["Empty or invalid CSV file"])
        }
        
        // Skip header row
        let dataLines = Array(lines.dropFirst())
        
        var imported = 0
        var duplicatesSkipped = 0
        var invalidRows = 0
        var errors: [String] = []
        var categories = existingCategories
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for (index, line) in dataLines.enumerated() {
            let lineNumber = index + 2 // +2 because we skip header and arrays are 0-indexed
            
            let fields = parseCSVLine(line)
            guard fields.count >= 3 else {
                invalidRows += 1
                errors.append("Line \(lineNumber): Not enough fields")
                continue
            }
            
            // Parse date
            guard let date = dateFormatter.date(from: fields[0]) else {
                invalidRows += 1
                errors.append("Line \(lineNumber): Invalid date format '\(fields[0])'")
                continue
            }
            
            // Parse amount
            guard let amount = Decimal(string: fields[1]), amount > 0 else {
                invalidRows += 1
                errors.append("Line \(lineNumber): Invalid amount '\(fields[1])'")
                continue
            }
            
            // Get or create category
            let categoryName = fields[2]
            var category = categories.first { $0.name.lowercased() == categoryName.lowercased() }
            if category == nil {
                // Create new category
                let newCategory = Category(
                    name: categoryName,
                    color: "gray",
                    symbolName: "square.grid.2x2.fill"
                )
                modelContext.insert(newCategory)
                categories.append(newCategory)
                category = newCategory
            }
            
            guard let finalCategory = category else {
                invalidRows += 1
                errors.append("Line \(lineNumber): Failed to create category '\(categoryName)'")
                continue
            }
            
            // Get notes (field 4 if present)
            let notes = fields.count > 3 && !fields[3].isEmpty ? fields[3] : nil
            
            // Check for duplicates
            let normalizedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let isDuplicate = existingExpenses.contains { expense in
                let expenseNormalizedNotes = expense.notes?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return Calendar.current.isDate(expense.date, inSameDayAs: date) &&
                       expense.amount == amount &&
                       expenseNormalizedNotes == normalizedNotes &&
                       expense.category.name.lowercased() == categoryName.lowercased()
            }
            
            if isDuplicate {
                duplicatesSkipped += 1
                continue
            }
            
            // Create and insert expense
            let expense = Expense(
                amount: amount,
                date: date,
                notes: notes,
                category: finalCategory
            )
            modelContext.insert(expense)
            imported += 1
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
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                let nextIndex = line.index(after: i)
                if insideQuotes && nextIndex < line.endIndex && line[nextIndex] == "\"" {
                    // Escaped quote
                    currentField += "\""
                    i = line.index(after: nextIndex)
                } else {
                    // Toggle quote state
                    insideQuotes.toggle()
                    i = nextIndex
                }
            } else if char == "," && !insideQuotes {
                // Field separator
                fields.append(currentField)
                currentField = ""
                i = line.index(after: i)
            } else {
                currentField += String(char)
                i = line.index(after: i)
            }
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields
    }
}

extension DateFormatter {
    func apply(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}