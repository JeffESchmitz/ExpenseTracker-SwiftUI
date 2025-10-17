//
//  PDFExportService.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 10/17/25.
//

import Foundation
import PDFKit
import SwiftData
import UIKit

struct PDFExportService {

    static func exportExpensesAsPDF(_ expenses: [Expense]) -> Data? {
        let pageFormat = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageFormat)

        let pdfData = renderer.pdfData { context in
            let bounds = pageFormat

            // Create pages
            let itemsPerPage = 15
            let totalPages = (expenses.count + itemsPerPage - 1) / itemsPerPage

            for pageIndex in 0..<totalPages {
                if pageIndex > 0 {
                    context.beginPage()
                }

                // Draw header
                drawHeader(in: bounds)

                // Draw table
                let startIndex = pageIndex * itemsPerPage
                let endIndex = min(startIndex + itemsPerPage, expenses.count)
                let pageExpenses = Array(expenses[startIndex..<endIndex])

                drawExpensesTable(pageExpenses, in: bounds)

                // Draw footer with page number
                drawFooter(in: bounds, pageNumber: pageIndex + 1)
            }
        }

        return pdfData
    }

    static func createTempPDFFile(data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = timestampFormatter.string(from: Date())
        let filename = "expenses-\(timestamp).pdf"
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to create PDF file: \(error)")
            return nil
        }
    }

    // MARK: - Private Helpers

    private static func drawHeader(in bounds: CGRect) {
        let headerRect = CGRect(x: 20, y: 20, width: bounds.width - 40, height: 40)

        let title = "Expense Report"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]

        let attributedString = NSAttributedString(string: title, attributes: attributes)
        attributedString.draw(in: headerRect)

        // Draw date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateText = "Generated: \(dateFormatter.string(from: Date()))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]

        let dateRect = CGRect(x: 20, y: 55, width: bounds.width - 40, height: 15)
        NSAttributedString(string: dateText, attributes: dateAttributes).draw(in: dateRect)
    }

    private static func drawExpensesTable(
        _ expenses: [Expense],
        in bounds: CGRect
    ) {
        let tableRect = CGRect(x: 20, y: 90, width: bounds.width - 40, height: bounds.height - 140)
        let columnWidth = tableRect.width / 4
        let rowHeight: CGFloat = 25

        // Draw table header
        let headerY = tableRect.minY
        drawTableRow(
            date: "Date",
            amount: "Amount",
            category: "Category",
            notes: "Notes",
            y: headerY,
            columnWidth: columnWidth,
            isHeader: true,
            tableRect: tableRect
        )

        // Draw rows
        var currentY = headerY + rowHeight
        for expense in expenses {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: expense.date)

            drawTableRow(
                date: dateString,
                amount: "$\(expense.amount)",
                category: expense.category.name,
                notes: expense.notes ?? "-",
                y: currentY,
                columnWidth: columnWidth,
                isHeader: false,
                tableRect: tableRect
            )

            currentY += rowHeight

            if currentY > tableRect.maxY - rowHeight {
                break
            }
        }
    }

    private static func drawTableRow(
        date: String,
        amount: String,
        category: String,
        notes: String,
        y: CGFloat,
        columnWidth: CGFloat,
        isHeader: Bool,
        tableRect: CGRect
    ) {
        let columns = [date, amount, category, notes]
        let fontSize: CGFloat = isHeader ? 11 : 10
        let fontColor: UIColor = isHeader ? .black : .darkGray
        let font: UIFont = isHeader ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)

        // Draw border line
        if isHeader {
            UIColor.black.setStroke()
            let line = UIBezierPath()
            line.move(to: CGPoint(x: tableRect.minX, y: y + 22))
            line.addLine(to: CGPoint(x: tableRect.maxX, y: y + 22))
            line.lineWidth = 1
            line.stroke()
        }

        // Draw each column
        for (index, text) in columns.enumerated() {
            let x = tableRect.minX + CGFloat(index) * columnWidth + 5
            let rect = CGRect(x: x, y: y + 2, width: columnWidth - 10, height: 20)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: fontColor
            ]

            let attributedString = NSAttributedString(string: text, attributes: attributes)
            attributedString.draw(in: rect)
        }
    }

    private static func drawFooter(in bounds: CGRect, pageNumber: Int) {
        let footerRect = CGRect(x: 20, y: bounds.height - 30, width: bounds.width - 40, height: 20)

        let pageText = "Page \(pageNumber)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.gray
        ]

        NSAttributedString(string: pageText, attributes: attributes).draw(in: footerRect)
    }
}
