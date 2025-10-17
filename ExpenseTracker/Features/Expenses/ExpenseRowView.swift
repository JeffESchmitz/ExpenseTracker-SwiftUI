//
//  ExpenseRowView.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack {
            // Category icon
            Image(systemName: expense.category.symbolName)
                .foregroundStyle(colorForCategory(expense.category.color))
                .font(.title2)
                .frame(width: 30)

            // Expense details
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.notes?.isEmpty == false ? expense.notes! : "No description")
                    .font(.body)
                    .lineLimit(2)

                Text(expense.date, format: .dateTime.year().month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            Text(expense.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.body)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 2)
    }

    private func colorForCategory(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "gray": return .gray
        case "green": return .green
        case "yellow": return .yellow
        default: return .blue
        }
    }
}

#Preview {
    List {
        ExpenseRowView(
            expense: Expense(
                amount: Decimal(25.50),
                date: Date(),
                notes: "Sample expense with notes",
                category: Category(name: "Food", color: "orange", symbolName: "fork.knife")
            )
        )

        ExpenseRowView(
            expense: Expense(
                amount: Decimal(150.00),
                date: Date(),
                notes: nil,
                category: Category(name: "Bills", color: "red", symbolName: "doc.text.fill")
            )
        )
    }
}
