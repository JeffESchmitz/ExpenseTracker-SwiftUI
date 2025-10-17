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
    @AppStorage("customStartDateTimestamp") private var customStartDateTimestamp: Double = 0
    @AppStorage("customEndDateTimestamp") private var customEndDateTimestamp: Double = 0
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
    @State private var showingExportMenu = false

    private var selectedFilter: DateRangeFilter {
        DateRangeFilter(rawValue: filterTypeRaw) ?? .defaultFilter
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
                // Demo Mode Section (extracted)
                SettingsDemoSection(
                    demoModeEnabled: $demoModeEnabled,
                    showingDemoDeleteConfirmation: $showingDemoDeleteConfirmation,
                    generateAction: generateDemoData,
                    modelContext: modelContext
                )

                // Data Section (extracted)
                SettingsDataSection(
                    exportFileURL: $exportFileURL,
                    showingImportPicker: $showingImportPicker,
                    showingExportMenu: $showingExportMenu,
                    filteredCount: filteredExpenses.count,
                    exportCSVAction: exportCSV,
                    exportJSONAction: exportJSON,
                    exportPDFAction: exportPDF,
                    exportExcelAction: exportExcel
                )

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

    private func exportJSON() {
        let jsonContent = CSVService.exportExpensesAsJSON(filteredExpenses)

        if let fileURL = CSVService.createTempJSONFile(content: jsonContent) {
            exportFileURL = fileURL

            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }

    private func exportPDF() {
        if let pdfData = PDFExportService.exportExpensesAsPDF(filteredExpenses) {
            if let fileURL = PDFExportService.createTempPDFFile(data: pdfData) {
                exportFileURL = fileURL

                // Success haptic
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
        }
    }

    private func exportExcel() {
        if let excelData = ExcelExportService.exportExpensesAsExcel(filteredExpenses) {
            if let fileURL = ExcelExportService.createTempExcelFile(data: excelData) {
                exportFileURL = fileURL

                // Success haptic
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
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
