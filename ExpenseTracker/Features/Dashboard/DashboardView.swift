//
//  DashboardView.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import SwiftUI
import SwiftData
import Charts

enum DashboardTimeRange: String, CaseIterable {
    case sixMonths = "6M"
    case twelveMonths = "12M"

    var displayName: String { rawValue }

    var monthsBack: Int {
        switch self {
        case .sixMonths: return 6
        case .twelveMonths: return 12
        }
    }
}

struct MonthlyData {
    let month: Date
    let amount: Decimal
    let monthName: String
}

struct CategoryData {
    let category: Category
    let amount: Decimal
    let percentage: Double
}

struct DashboardView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var categories: [Category]
    @Environment(\.modelContext) private var modelContext

    // Filter persistence - read from same AppStorage as ExpenseListView
    @AppStorage("filterType") private var filterTypeRaw = DateRangeFilter.defaultFilter.rawValue
    @AppStorage("customStartDateTimestamp") private var customStartDateTimestamp: Double = 0
    @AppStorage("customEndDateTimestamp") private var customEndDateTimestamp: Double = 0
    @AppStorage("selectedCategoryName") private var selectedCategoryName: String?
    @AppStorage("dashboardTimeRange") private var timeRangeRaw = DashboardTimeRange.twelveMonths.rawValue

    @State private var showingCustomDateSheet = false

    private var selectedFilter: DateRangeFilter {
        DateRangeFilter(rawValue: filterTypeRaw) ?? .defaultFilter
    }

    private var selectedCategory: Category? {
        guard let categoryName = selectedCategoryName else { return nil }
        return categories.first { $0.name == categoryName }
    }

    private var dashboardTimeRange: DashboardTimeRange {
        DashboardTimeRange(rawValue: timeRangeRaw) ?? .twelveMonths
    }

    private var customStartDate: Date? {
        get {
            customStartDateTimestamp == 0 ? nil : Date(timeIntervalSince1970: customStartDateTimestamp)
        }
        set {
            customStartDateTimestamp = newValue?.timeIntervalSince1970 ?? 0
        }
    }

    private var customEndDate: Date? {
        get {
            customEndDateTimestamp == 0 ? nil : Date(timeIntervalSince1970: customEndDateTimestamp)
        }
        set {
            customEndDateTimestamp = newValue?.timeIntervalSince1970 ?? 0
        }
    }

    // Filter expenses based on current filters from ExpenseListView
    private var filteredExpenses: [Expense] {
        var result = expenses

        // Apply date range filter
        if let dateRange = selectedFilter.dateRange(customStart: customStartDate, customEnd: customEndDate) {
            result = result.filter { expense in
                expense.date >= dateRange.start && expense.date <= dateRange.end
            }
        }

        // Apply category filter
        if let selectedCategory = selectedCategory {
            result = result.filter { expense in
                expense.category.name == selectedCategory.name
            }
        }

        return result
    }

    // Get monthly data for charts
    private var monthlyData: [MonthlyData] {
        let calendar = Calendar.current
        let now = Date()
        let monthsBack = dashboardTimeRange.monthsBack

        // Create array of months to include
        var monthsToShow: [Date] = []
        for monthOffset in 0..<monthsBack {
            if let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) {
                let interval = calendar.dateInterval(of: .month, for: monthDate)
                monthsToShow.append(interval?.start ?? monthDate)
            }
        }
        monthsToShow.reverse()

        // Group expenses by month for the chart time range
        let expensesForChart = expenses.filter { expense in
            let monthsAgo = calendar.dateComponents([.month], from: expense.date, to: now).month ?? 0
            return monthsAgo < monthsBack
        }

        // Apply category filter for chart if active
        let chartExpenses = selectedCategory != nil ?
            expensesForChart.filter { $0.category.name == selectedCategory?.name } : expensesForChart

        let groupedByMonth = Dictionary(grouping: chartExpenses) { expense in
            calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return monthsToShow.map { month in
            let monthExpenses = groupedByMonth[month] ?? []
            let total = monthExpenses.reduce(Decimal.zero) { $0 + $1.amount }
            return MonthlyData(
                month: month,
                amount: total,
                monthName: formatter.string(from: month)
            )
        }
    }

    // Get category breakdown for pie chart (always show all categories within date range)
    private var categoryData: [CategoryData] {
        // Use filtered expenses for the date range, but show all categories
        let expensesInDateRange = expenses.filter { expense in
            if let dateRange = selectedFilter.dateRange(customStart: customStartDate, customEnd: customEndDate) {
                return expense.date >= dateRange.start && expense.date <= dateRange.end
            }
            return true
        }

        let groupedByCategory = Dictionary(grouping: expensesInDateRange) { $0.category.name }
        let total = expensesInDateRange.reduce(Decimal.zero) { $0 + $1.amount }

        guard total > 0 else { return [] }

        return groupedByCategory.compactMap { (categoryName, expenses) in
            guard let category = categories.first(where: { $0.name == categoryName }) else { return nil }
            let categoryTotal = expenses.reduce(Decimal.zero) { $0 + $1.amount }
            let percentage = Double(truncating: categoryTotal as NSDecimalNumber) /
                Double(truncating: total as NSDecimalNumber) * 100
            return CategoryData(category: category, amount: categoryTotal, percentage: percentage)
        }.sorted { $0.amount > $1.amount }
    }

    // Summary card data
    private var totalAmount: Decimal {
        filteredExpenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var periodLabel: String {
        selectedFilter.shortDisplayName
    }

    private var monthlyTrendData: (amount: Decimal, percentage: Double)? {
        let calendar = Calendar.current
        let now = Date()

        // Current period amount
        let currentAmount = totalAmount

        // Get previous period
        let previousPeriodExpenses: [Expense]

        switch selectedFilter {
        case .thisMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
                  let lastMonthRange = calendar.dateInterval(of: .month, for: lastMonth) else {
                return nil
            }
            previousPeriodExpenses = expenses.filter { expense in
                expense.date >= lastMonthRange.start && expense.date <= lastMonthRange.end
            }

        case .lastMonth:
            guard let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now),
                  let twoMonthsAgoRange = calendar.dateInterval(of: .month, for: twoMonthsAgo) else {
                return nil
            }
            previousPeriodExpenses = expenses.filter { expense in
                expense.date >= twoMonthsAgoRange.start && expense.date <= twoMonthsAgoRange.end
            }

        case .last7Days:
            guard let startDate = calendar.date(byAdding: .day, value: -14, to: now),
                  let endDate = calendar.date(byAdding: .day, value: -7, to: now) else {
                return nil
            }
            previousPeriodExpenses = expenses.filter { expense in
                expense.date >= startDate && expense.date <= endDate
            }

        case .last30Days:
            guard let startDate = calendar.date(byAdding: .day, value: -60, to: now),
                  let endDate = calendar.date(byAdding: .day, value: -30, to: now) else {
                return nil
            }
            previousPeriodExpenses = expenses.filter { expense in
                expense.date >= startDate && expense.date <= endDate
            }

        default:
            return nil
        }

        // Apply same category filter to previous period
        let filteredPreviousExpenses = selectedCategory != nil ?
            previousPeriodExpenses.filter { $0.category.name == selectedCategory?.name } :
            previousPeriodExpenses

        let previousAmount = filteredPreviousExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        let difference = currentAmount - previousAmount

        let percentage = previousAmount > 0 ?
            (Double(truncating: difference as NSDecimalNumber) /
             Double(truncating: previousAmount as NSDecimalNumber)) * 100 : 0

        return (amount: difference, percentage: percentage)
    }

    private var topCategory: CategoryData? {
        categoryData.first
    }

    private var hasData: Bool {
        !filteredExpenses.isEmpty
    }

    var body: some View {
        NavigationStack {
            if hasData {
                ScrollView {
                    VStack(spacing: 16) {
                        // Summary Cards
                        VStack(spacing: 12) {
                            SummaryCardView(
                                title: "Total",
                                amount: totalAmount,
                                subtitle: periodLabel,
                                icon: "dollarsign.circle.fill"
                            )

                            if let trendData = monthlyTrendData {
                                TrendCardView(
                                    difference: trendData.amount,
                                    percentage: trendData.percentage
                                )
                            }

                            if let topCategory = topCategory {
                                TopCategoryCardView(categoryData: topCategory)
                            }
                        }
                        .padding(.horizontal)

                        // Chart Time Range Toggle
                        VStack(spacing: 16) {
                            HStack {
                                Text("Trends")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Spacer()
                                Picker("Time Range", selection: $timeRangeRaw) {
                                    ForEach(DashboardTimeRange.allCases, id: \.self) { range in
                                        Text(range.displayName).tag(range.rawValue)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 100)
                            }
                            .padding(.horizontal)

                            // Monthly Trend Chart
                            MonthlyTrendChartView(monthlyData: monthlyData)
                        }

                        // Category Breakdown Chart
                        if categoryData.count > 1 {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Category Breakdown")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)

                                CategoryBreakdownChartView(categoryData: categoryData)
                            }
                        }

                        // Budget Overview
                        BudgetProgressCard()
                    }
                    .padding(.vertical)
                }
                .animation(.snappy, value: dashboardTimeRange)
                .animation(.snappy, value: filteredExpenses.count)
            } else {
                DashboardEmptyStateView(onShowFilters: { showingCustomDateSheet = true })
            }
        }
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showingCustomDateSheet) {
            CustomDateRangeSheet(
                initialStart: customStartDate,
                initialEnd: customEndDate
            ) { start, end in
                customStartDateTimestamp = start.timeIntervalSince1970
                customEndDateTimestamp = end.timeIntervalSince1970
                filterTypeRaw = DateRangeFilter.custom.rawValue
            }
        }
    }
}

#Preview {
    DashboardView()
}
