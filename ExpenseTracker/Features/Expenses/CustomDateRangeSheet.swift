//
//  CustomDateRangeSheet.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
//

import SwiftUI

struct CustomDateRangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var showingDateError = false
    
    let onApply: (Date, Date) -> Void
    
    init(initialStart: Date? = nil, initialEnd: Date? = nil, onApply: @escaping (Date, Date) -> Void) {
        self.onApply = onApply
        self._startDate = State(initialValue: initialStart ?? Date())
        self._endDate = State(initialValue: initialEnd ?? Date())
    }
    
    private var isValidDateRange: Bool {
        startDate <= endDate
    }
    
    private var dateError: String? {
        if !isValidDateRange {
            return "Start date must be before or equal to end date"
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    if let error = dateError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Custom Date Range")
                }
                
                Section("Quick Shortcuts") {
                    Button("Last 7 Days") {
                        setQuickRange(.last7Days)
                    }
                    
                    Button("Last 30 Days") {
                        setQuickRange(.last30Days)
                    }
                    
                    Button("Year to Date") {
                        setQuickRange(.yearToDate)
                    }
                }
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        applyDateRange()
                    }
                    .disabled(!isValidDateRange)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func setQuickRange(_ filter: DateRangeFilter) {
        guard let range = filter.dateRange() else { return }
        startDate = range.start
        endDate = range.end
    }
    
    private func applyDateRange() {
        guard isValidDateRange else { return }
        onApply(startDate, endDate)
        dismiss()
    }
}

#Preview {
    CustomDateRangeSheet { _, _ in }
}