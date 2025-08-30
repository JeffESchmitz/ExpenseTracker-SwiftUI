//
//  DashboardView.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
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
    @AppStorage("customStartDate") private var customStartDate: Date?
    @AppStorage("customEndDate") private var customEndDate: Date?
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
        for i in 0..<monthsBack {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: now) {
                monthsToShow.append(calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate)
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
            let percentage = Double(truncating: categoryTotal as NSDecimalNumber) / Double(truncating: total as NSDecimalNumber) * 100
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
            previousPeriodExpenses.filter { $0.category.name == selectedCategory?.name } : previousPeriodExpenses
        
        let previousAmount = filteredPreviousExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        let difference = currentAmount - previousAmount
        
        let percentage = previousAmount > 0 ? 
            (Double(truncating: difference as NSDecimalNumber) / Double(truncating: previousAmount as NSDecimalNumber)) * 100 : 0
        
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
                            summaryCard(
                                title: "Total",
                                amount: totalAmount,
                                subtitle: periodLabel,
                                icon: "dollarsign.circle.fill"
                            )
                            
                            if let trendData = monthlyTrendData {
                                trendCard(
                                    difference: trendData.amount,
                                    percentage: trendData.percentage
                                )
                            }
                            
                            if let topCategory = topCategory {
                                topCategoryCard(categoryData: topCategory)
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
                            monthlyTrendChart
                        }
                        
                        // Category Breakdown Chart
                        if categoryData.count > 1 {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Category Breakdown")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                categoryBreakdownChart
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .animation(.snappy, value: dashboardTimeRange)
                .animation(.snappy, value: filteredExpenses.count)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showingCustomDateSheet) {
            CustomDateRangeSheet(
                initialStart: customStartDate,
                initialEnd: customEndDate
            ) { start, end in
                customStartDate = start
                customEndDate = end
                filterTypeRaw = DateRangeFilter.custom.rawValue
            }
        }
    }
    
    private func summaryCard(title: String, amount: Decimal, subtitle: String, icon: String) -> some View {
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
    
    private func trendCard(difference: Decimal, percentage: Double) -> some View {
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
                    + Text(difference, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    Text("(\(difference >= 0 ? "+" : "")\(percentage, format: .percent.precision(.fractionLength(0))))")
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
    
    private func topCategoryCard(categoryData: CategoryData) -> some View {
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
                Text("\(categoryData.percentage, format: .percent.precision(.fractionLength(0))) of total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(categoryData.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var monthlyTrendChart: some View {
        Chart(monthlyData, id: \.month) { data in
            BarMark(
                x: .value("Month", data.monthName),
                y: .value("Amount", Double(truncating: data.amount as NSDecimalNumber))
            )
            .foregroundStyle(.blue.gradient)
            .accessibilityLabel("Month: \(data.monthName)")
            .accessibilityValue("Amount: \(data.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
        }
        .frame(height: 200)
        .padding(.horizontal)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var categoryBreakdownChart: some View {
        VStack {
            Chart(categoryData, id: \.category.name) { data in
                SectorMark(
                    angle: .value("Amount", Double(truncating: data.amount as NSDecimalNumber)),
                    innerRadius: .ratio(0.4),
                    angularInset: 1
                )
                .foregroundStyle(colorForCategory(data.category.color))
                .accessibilityLabel("\(data.category.name): \(data.percentage, format: .percent.precision(.fractionLength(1)))")
                .accessibilityValue("Amount: \(data.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
            }
            .frame(height: 250)
            
            // Legend
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(categoryData, id: \.category.name) { data in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colorForCategory(data.category.color))
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(data.category.name)
                                .font(.caption)
                                .lineLimit(1)
                            Text("\(data.percentage, format: .percent.precision(.fractionLength(0)))")
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
    
    private var emptyStateView: some View {
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
                    showingCustomDateSheet = true
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
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
    
    #if DEBUG
    private func insertSampleExpenses() {
        let categories = try? modelContext.fetch(FetchDescriptor<Category>())
        guard let categories = categories, !categories.isEmpty else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Create sample expenses across 12 months with varied amounts
        var sampleExpenses: [Expense] = []
        
        for monthsAgo in 0..<12 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthsAgo, to: now) else { continue }
            
            // Create 5-15 expenses per month with realistic variation
            let expenseCount = Int.random(in: 5...15)
            
            for _ in 0..<expenseCount {
                let randomDay = Int.random(in: 1...28)
                guard let expenseDate = calendar.date(bySetting: .day, value: randomDay, of: monthDate) else { continue }
                
                let randomCategory = categories.randomElement()!
                let baseAmount = Decimal(Double.random(in: 10...200))
                let notes = ["Groceries", "Coffee", "Gas", "Dinner", "Shopping", "Bills", "Entertainment", nil].randomElement()!
                
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

#Preview {
    DashboardView()
}