//
//  SettingsView+Sections.swift
//  ExpenseTracker
//
//  Extracted subviews for SettingsView to reduce file length for linting.
//

import SwiftUI
import SwiftData

struct SettingsDemoSection: View {
    @Binding var demoModeEnabled: Bool
    @Binding var showingDemoDeleteConfirmation: Bool
    var generateAction: () -> Void

    var body: some View {
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

            if demoModeEnabled {
                let demoCount = DemoDataService.countDemoExpenses(modelContext: ModelContext.shared)

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
                            generateAction()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        generateAction()
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
    }
}

struct SettingsDataSection: View {
    @Binding var exportFileURL: URL?
    @Binding var showingImportPicker: Bool
    var filteredCount: Int
    var exportAction: () -> Void

    var body: some View {
        Section {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Export CSV")
                        .font(.body)
                    Text("Export \(filteredCount) filtered expense\(filteredCount == 1 ? "" : "s")")
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
                        exportAction()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if exportFileURL == nil {
                    exportAction()
                }
            }

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
    }
}
