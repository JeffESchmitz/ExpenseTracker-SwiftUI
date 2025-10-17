//
//  DashboardComponents.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import SwiftUI
import Charts

// MARK: - Summary Cards

struct SummaryCardView: View {
    let title: String
    let amount: Decimal
    let subtitle: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TrendCardView: View {
    let difference: Decimal
    let percentage: Double

    var body: some View {
        HStack {
            Image(systemName: difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.title2)
                .foregroundStyle(difference >= 0 ? .red : .green)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("Monthly Trend")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text(difference >= 0 ? "+" : "")
                    + Text(
                        difference,
                        format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                    )
                    Text(
                        "(\(difference >= 0 ? "+" : "")\(percentage, format: .percent.precision(.fractionLength(0))))"
                    )
                    .foregroundStyle(.secondary)
                }
                .font(.title3)
                .fontWeight(.semibold)

                Text("vs last month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TopCategoryCardView: View {
    let categoryData: CategoryData

    var body: some View {
        HStack {
            Image(systemName: categoryData.category.symbolName)
                .font(.title2)
                .foregroundStyle(colorForCategory(categoryData.category.color))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("Top Category")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(categoryData.category.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(
                    "\(categoryData.percentage, format: .percent.precision(.fractionLength(0))) of total"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(
                categoryData.amount,
                format: .currency(code: Locale.current.currency?.identifier ?? "USD")
            )
            .font(.title3)
            .fontWeight(.semibold)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Charts

struct MonthlyTrendChartView: View {
    let monthlyData: [MonthlyData]

    var body: some View {
        Chart(monthlyData, id: \.month) { data in
            BarMark(
                x: .value("Month", data.monthName),
                y: .value("Amount", Double(truncating: data.amount as NSDecimalNumber))
            )
            .foregroundStyle(.blue.gradient)
            .accessibilityLabel("Month: \(data.monthName)")
            .accessibilityValue(
                "Amount: \(data.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))"
            )
        }
        .frame(height: 200)
        .padding(.horizontal)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct CategoryBreakdownChartView: View {
    let categoryData: [CategoryData]

    var body: some View {
        VStack {
            Chart(categoryData, id: \.category.name) { data in
                SectorMark(
                    angle: .value("Amount", Double(truncating: data.amount as NSDecimalNumber)),
                    innerRadius: .ratio(0.4),
                    angularInset: 1
                )
                .foregroundStyle(colorForCategory(data.category.color))
                .accessibilityLabel(
                    "\(data.category.name): \(data.percentage, format: .percent.precision(.fractionLength(1)))"
                )
                .accessibilityValue(
                    "Amount: \(data.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))"
                )
            }
            .frame(height: 250)

            // Legend
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 8
            ) {
                ForEach(categoryData, id: \.category.name) { data in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colorForCategory(data.category.color))
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(data.category.name)
                                .font(.caption)
                                .lineLimit(1)
                            Text(
                                "\(data.percentage, format: .percent.precision(.fractionLength(0)))"
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Empty State

struct DashboardEmptyStateView: View {
    @Environment(\.modelContext) private var modelContext

    var onShowFilters: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No data for charts",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Add expenses or adjust filters to see trends.")
            )

            VStack(spacing: 8) {
                #if DEBUG
                Button("Insert Sample Data (Debug)") {
                    insertSampleExpenses()
                }
                .buttonStyle(.borderedProminent)
                #endif

                Button("Adjust Filters…") {
                    onShowFilters()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }

    #if DEBUG
    private func insertSampleExpenses() {
        let categories = try? modelContext.fetch(FetchDescriptor<Category>())
        guard let categories = categories, !categories.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()

        // Create sample expenses across 12 months with varied amounts
        var sampleExpenses: [Expense] = []

        for monthsAgo in 0..<12 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthsAgo, to: now) else {
                continue
            }

            // Create 5-15 expenses per month with realistic variation
            let expenseCount = Int.random(in: 5...15)

            for _ in 0..<expenseCount {
                let randomDay = Int.random(in: 1...28)
                guard let expenseDate = calendar.date(bySetting: .day, value: randomDay, of: monthDate)
                else {
                    continue
                }

                let randomCategory = categories.randomElement()!
                let baseAmount = Decimal(Double.random(in: 10...200))
                let notes = [
                    "Groceries", "Coffee", "Gas", "Dinner", "Shopping", "Bills", "Entertainment", nil
                ].randomElement()!

                sampleExpenses.append(Expense(
                    amount: baseAmount,
                    date: expenseDate,
                    notes: notes,
                    category: randomCategory
                ))
            }
        }

        for expense in sampleExpenses {
            modelContext.insert(expense)
        }

        try? modelContext.save()
    }
    #endif
}

// MARK: - Helpers

func colorForCategory(_ colorName: String) -> Color {
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

