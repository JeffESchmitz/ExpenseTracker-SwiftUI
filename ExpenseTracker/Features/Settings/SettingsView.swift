//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
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
    
    // Demo mode persistence
    @AppStorage("demoModeEnabled") private var demoModeEnabled = false
    
    @State private var exportFileURL: URL?
    @State private var showingImportPicker = false
    @State private var showingImportResult = false
    @State private var importResult: CSVService.ImportResult?
    @State private var showingDemoDeleteConfirmation = false
    @State private var showingDemoDataResult = false
    @State private var demoDataResultMessage = ""
    
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
                // Demo Mode Section
                Section {
                    HStack {
                        Image(systemName: "theatermasks")
                            .foregroundStyle(demoModeEnabled ? .orange : .secondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Demo Mode")
                                .font(.body)
                            if demoModeEnabled {
                                Text("Show realistic sample expenses")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Use your real expense data")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $demoModeEnabled)
                    }
                    
                    // Demo actions
                    if demoModeEnabled {
                        let demoCount = DemoDataService.countDemoExpenses(modelContext: modelContext)
                        
                        if demoCount == 0 {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.green)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Generate Demo Data")
                                        .font(.body)
                                    Text("Create 80-120 sample expenses")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Generate") {
                                    generateDemoData()
                                }
                                .font(.subheadline)
                                .foregroundStyle(.green)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                generateDemoData()
                            }
                        } else {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Remove Demo Data")
                                        .font(.body)
                                    Text("\(demoCount) demo expense\(demoCount == 1 ? "" : "s") found")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Remove") {
                                    showingDemoDeleteConfirmation = true
                                }
                                .font(.subheadline)
                                .foregroundStyle(.red)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingDemoDeleteConfirmation = true
                            }
                        }
                    }
                    
                } header: {
                    Text("Demo Mode")
                } footer: {
                    Text("Demo mode shows realistic sample data for exploring the app. Your real expenses are preserved.")
                        .font(.caption)
                }
                
                // Data Section
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
                
                // App Info Section
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
                    
                    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        HStack {
                            Image(systemName: "number")
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Version")
                                    .font(.body)
                                Text("\(appVersion) (\(buildNumber))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("App Info")
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
            .alert("Remove Demo Data", isPresented: $showingDemoDeleteConfirmation) {
                Button("Remove", role: .destructive) {
                    removeDemoData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove all demo expenses. Your real expenses will remain unchanged.")
            }
            .alert("Demo Data Result", isPresented: $showingDemoDataResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(demoDataResultMessage)
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
    
    private func generateDemoData() {
        print("⚙️ SettingsView: Generate demo data button pressed")
        print("⚙️ SettingsView: Categories available: \(categories.count)")
        for category in categories {
            print("⚙️ SettingsView: Category: \(category.name)")
        }
        
        let count = DemoDataService.insertDemoData(modelContext: modelContext, categories: categories)
        print("⚙️ SettingsView: Demo data generation returned count: \(count)")
        
        if count > 0 {
            print("⚙️ SettingsView: Demo data generated successfully, playing haptic")
            demoDataResultMessage = "Successfully generated \(count) demo expenses!\n\nNote: Demo expenses span 6-12 months. Use 'All Time' filter in Expenses tab to see them all."
            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        } else {
            print("⚙️ SettingsView: Demo data generation failed or returned 0")
            if categories.isEmpty {
                demoDataResultMessage = "Failed: No categories found. Please add categories first."
            } else {
                demoDataResultMessage = "Failed to generate demo data. Check console for details."
            }
        }
        
        showingDemoDataResult = true
    }
    
    private func removeDemoData() {
        let count = DemoDataService.removeDemoData(modelContext: modelContext)
        
        if count > 0 {
            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
}

#Preview {
    SettingsView()
}