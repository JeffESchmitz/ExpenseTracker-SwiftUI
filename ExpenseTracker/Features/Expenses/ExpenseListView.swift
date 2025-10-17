//
//  ExpenseListView.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var categories: [Category]

    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingCustomDateSheet = false
    @State private var expenseToDelete: Expense?
    @State private var expenseToEdit: Expense?
    @State private var exportFileURL: URL?
    @Environment(\.modelContext) private var modelContext

    // Filter persistence with AppStorage
    @AppStorage("filterType") private var filterTypeRaw = DateRangeFilter.defaultFilter.rawValue
    @AppStorage("customStartDateTimestamp") private var customStartDateTimestamp: Double = 0
    @AppStorage("customEndDateTimestamp") private var customEndDateTimestamp: Double = 0
    @AppStorage("selectedCategoryName") private var selectedCategoryName: String?

    private var selectedFilter: DateRangeFilter {
        DateRangeFilter(rawValue: filterTypeRaw) ?? .defaultFilter
    }

    private var selectedCategory: Category? {
        guard let categoryName = selectedCategoryName else { return nil }
        return categories.first { $0.name == categoryName }
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

    private var hasActiveFilters: Bool {
        selectedFilter != .defaultFilter || selectedCategory != nil
    }

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

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { expense in
                let notesMatch = expense.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                let categoryMatch = expense.category.name.localizedCaseInsensitiveContains(searchText)
                return notesMatch || categoryMatch
            }
        }

        return result
    }

    private var navigationTitle: String {
        if selectedFilter == .defaultFilter {
            return "Expenses"
        } else {
            return "Expenses • \(selectedFilter.shortDisplayName)"
        }
    }

    private var activeFiltersDescription: String? {
        guard hasActiveFilters else { return nil }

        var components: [String] = []

        // Add date range info
        if let dateRange = selectedFilter.dateRange(customStart: customStartDate, customEnd: customEndDate) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            components.append("Range: \(formatter.string(from: dateRange.start)) – \(formatter.string(from: dateRange.end))")
        }

        // Add category info
        if let category = selectedCategory {
            components.append("Category: \(category.name)")
        }

        return components.joined(separator: ", ")
    }

    private var shouldShowNoResultsForFilters: Bool {
        filteredExpenses.isEmpty && !expenses.isEmpty && (hasActiveFilters || !searchText.isEmpty)
    }

    private var filterEmptyStateView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No results",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("No expenses match your current filters.")
            )

            VStack(spacing: 8) {
                Button("Clear Filters") {
                    clearAllFilters()
                }
                .buttonStyle(.borderedProminent)

                Button("Adjust Filters…") {
                    showingCustomDateSheet = true
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredExpenses.isEmpty {
                    if expenses.isEmpty {
                        // No expenses at all
                        ContentUnavailableView(
                            "No expenses",
                            systemImage: "tray",
                            description: Text("Add your first expense.")
                        )
                    } else if shouldShowNoResultsForFilters {
                        // No results after applying filters
                        filterEmptyStateView
                    } else {
                        // No search results
                        ContentUnavailableView.search
                    }
                } else {
                    VStack(spacing: 0) {
                        // Active filters indicator
                        if hasActiveFilters, let description = activeFiltersDescription {
                            HStack {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)

                                Spacer()

                                Button("Clear") {
                                    clearAllFilters()
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }

                        List {
                            ForEach(filteredExpenses) { expense in
                                ExpenseRowView(expense: expense)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        expenseToEdit = expense
                                        showingEditSheet = true
                                    }
                                    .accessibilityAddTraits(.isButton)
                            }
                            .onDelete(perform: deleteExpenses)
                        }
                        .animation(.snappy, value: filteredExpenses)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .searchable(text: $searchText, prompt: "Search expenses...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        // Date Range Filters
                        ForEach(DateRangeFilter.allCases.filter { $0 != .custom }, id: \.self) { filter in
                            Button(filter.displayName) {
                                selectDateRangeFilter(filter)
                            }
                        }

                        Button("Custom…") {
                            showingCustomDateSheet = true
                        }

                        Divider()

                        // Category Filters
                        Button("All Categories") {
                            selectedCategoryName = nil
                        }

                        ForEach(categories, id: \.name) { category in
                            Button(category.name) {
                                selectedCategoryName = category.name
                            }
                        }

                        Divider()

                        Button("Clear Filters") {
                            clearAllFilters()
                        }

                        #if DEBUG
                        if expenses.isEmpty {
                            Divider()
                            Button("Insert Sample Expenses (Debug)") {
                                insertSampleExpenses()
                            }
                        }
                        #endif
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? .blue : .primary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        // Export button (optional nice-to-have)
                        if !filteredExpenses.isEmpty {
                            if let url = exportFileURL {
                                ShareLink(item: url) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            } else {
                                Button {
                                    exportCSV()
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        }

                        // Add expense button
                        Button {
                            showingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddExpenseSheet()
            }
            .sheet(isPresented: $showingEditSheet) {
                if let expenseToEdit = expenseToEdit {
                    AddExpenseSheet(expense: expenseToEdit)
                }
            }
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
            .alert("Delete Expense", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this expense?")
            }
        }
    }

    private func deleteExpenses(offsets: IndexSet) {
        for index in offsets {
            expenseToDelete = filteredExpenses[index]
            showingDeleteConfirmation = true
        }
    }

    private func confirmDelete() {
        guard let expenseToDelete = expenseToDelete else { return }

        modelContext.delete(expenseToDelete)

        do {
            try modelContext.save()
            // Success haptic
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } catch {
            print("Failed to delete expense: \(error)")
        }

        self.expenseToDelete = nil
    }

    private func selectDateRangeFilter(_ filter: DateRangeFilter) {
        filterTypeRaw = filter.rawValue
        // Clear custom dates when switching to preset filters
        if filter != .custom {
            customStartDateTimestamp = 0
            customEndDateTimestamp = 0
        }
    }

    private func clearAllFilters() {
        filterTypeRaw = DateRangeFilter.defaultFilter.rawValue
        selectedCategoryName = nil
        customStartDateTimestamp = 0
        customEndDateTimestamp = 0
    }

    private func exportCSV() {
        let csvContent = CSVService.exportExpenses(filteredExpenses)

        if let fileURL = CSVService.createTempCSVFile(content: csvContent) {
            exportFileURL = fileURL

            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }

    #if DEBUG
    private func insertSampleExpenses() {
        let categories = try? modelContext.fetch(FetchDescriptor<Category>())
        guard let categories = categories, !categories.isEmpty else { return }

        let sampleExpenses = [
            Expense(
                amount: Decimal(25.50),
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                notes: "Lunch at downtown café",
                category: categories.first { $0.name == "Food" } ?? categories[0]
            ),
            Expense(
                amount: Decimal(15.00),
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                notes: "Bus fare",
                category: categories.first { $0.name == "Transportation" } ?? categories[0]
            ),
            Expense(
                amount: Decimal(45.99),
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                notes: "Movie tickets and popcorn",
                category: categories.first { $0.name == "Entertainment" } ?? categories[0]
            ),
            Expense(
                amount: Decimal(120.75),
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                notes: "Grocery shopping",
                category: categories.first { $0.name == "Shopping" } ?? categories[0]
            ),
            Expense(
                amount: Decimal(89.99),
                date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                notes: nil,
                category: categories.first { $0.name == "Bills" } ?? categories[0]
            )
        ]

        for expense in sampleExpenses {
            modelContext.insert(expense)
        }

        try? modelContext.save()
    }
    #endif
}

#Preview {
    ExpenseListView()
}
