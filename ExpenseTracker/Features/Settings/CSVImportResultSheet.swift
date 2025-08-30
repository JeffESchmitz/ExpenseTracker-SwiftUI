//
//  CSVImportResultSheet.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/30/25.
//

import SwiftUI

struct CSVImportResultSheet: View {
    let result: CSVService.ImportResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Summary Cards
                    VStack(spacing: 12) {
                        summaryCard(
                            title: "Imported",
                            value: result.imported,
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        if result.duplicatesSkipped > 0 {
                            summaryCard(
                                title: "Duplicates Skipped",
                                value: result.duplicatesSkipped,
                                icon: "arrow.triangle.2.circlepath",
                                color: .orange
                            )
                        }
                        
                        if result.invalidRows > 0 {
                            summaryCard(
                                title: "Invalid Rows",
                                value: result.invalidRows,
                                icon: "exclamationmark.triangle.fill",
                                color: .red
                            )
                        }
                    }
                    
                    // Error Details
                    if !result.errors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Error Details")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(result.errors, id: \.self) { error in
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                            .padding()
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    // Success Message
                    if result.imported > 0 {
                        HStack {
                            Image(systemName: "party.popper.fill")
                                .foregroundStyle(.blue)
                            Text("Successfully imported \(result.imported) expense\(result.imported == 1 ? "" : "s")!")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            .navigationTitle("Import Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            // Success haptic if we imported anything
            if result.imported > 0 {
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
        }
    }
    
    private func summaryCard(title: String, value: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CSVImportResultSheet(
        result: CSVService.ImportResult(
            imported: 15,
            duplicatesSkipped: 3,
            invalidRows: 2,
            errors: ["Line 5: Invalid date format '2025-13-45'", "Line 8: Invalid amount 'abc'"]
        )
    )
}