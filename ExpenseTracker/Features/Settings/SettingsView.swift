//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var categories: [Category]
    @Environment(\.modelContext) private var modelContext
    
    // Filter persistence - read from same AppStorage as ExpenseListView
    @AppStorage("filterType") private var filterTypeRaw = DateRangeFilter.defaultFilter.rawValue
    @AppStorage("customStartDate") private var customStartDate: Date?
    @AppStorage("customEndDate") private var customEndDate: Date?
    @AppStorage("selectedCategoryName") private var selectedCategoryName: String?
    @AppStorage("searchText") private var searchText = ""
    
    @State private var exportFileURL: URL?
    @State private var showingImportPicker = false
    @State private var showingImportResult = false
    @State private var importResult: CSVService.ImportResult?
    
    private var selectedFilter: DateRangeFilter {
        DateRangeFilter(rawValue: filterTypeRaw) ?? .defaultFilter
    }
    
    private var selectedCategory: Category? {
        guard let categoryName = selectedCategoryName else { return nil }
        return categories.first { $0.name == categoryName }
    }
    
    // Get filtered expenses based on current filters from ExpenseListView
    private var filteredExpenses: [Expense] {
        var result = expenses
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { expense in
                expense.category.name.localizedCaseInsensitiveContains(searchText) ||
                (expense.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Export CSV
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export CSV")
                                .font(.body)
                            Text("Export \(filteredExpenses.count) filtered expense\(filteredExpenses.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if let url = exportFileURL {
                            ShareLink(item: url) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                        } else {
                            Button("Export") {
                                exportCSV()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if exportFileURL == nil {
                            exportCSV()
                        }
                    }
                    
                    // Import CSV
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundStyle(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import CSV")
                                .font(.body)
                            Text("Import expenses from CSV file")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Import") {
                            showingImportPicker = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingImportPicker = true
                    }
                    
                } header: {
                    Text("Data")
                } footer: {
                    Text("CSV uses ISO dates (yyyy-MM-dd) and decimal amounts.")
                        .font(.caption)
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ExpenseTracker")
                                .font(.body)
                            Text("Built with SwiftUI & SwiftData")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .sheet(isPresented: $showingImportResult) {
                if let result = importResult {
                    CSVImportResultSheet(result: result)
                }
            }
        }
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
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            let result = CSVService.importCSV(
                from: url,
                into: modelContext,
                existingExpenses: expenses,
                existingCategories: categories
            )
            
            self.importResult = result
            showingImportResult = true
            
        case .failure(let error):
            print("Failed to import CSV: \(error)")
            
            self.importResult = CSVService.ImportResult(
                imported: 0,
                duplicatesSkipped: 0,
                invalidRows: 1,
                errors: ["Failed to import: \(error.localizedDescription)"]
            )
            showingImportResult = true
        }
    }
}

#Preview {
    SettingsView()
}