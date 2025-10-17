//
//  DateRangeFilter.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import Foundation

enum DateRangeFilter: String, CaseIterable {
    case allTime
    case thisMonth
    case lastMonth
    case last7Days
    case last30Days
    case yearToDate
    case custom

    var displayName: String {
        switch self {
        case .allTime: return "All Time"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .yearToDate: return "Year to Date"
        case .custom: return "Custom"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .allTime: return "All Time"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .yearToDate: return "Year to Date"
        case .custom: return "Custom"
        }
    }

    func dateRange(customStart: Date? = nil, customEnd: Date? = nil) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .allTime:
            return nil // No date filtering
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return (startOfMonth, endOfMonth)

        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
                  let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start,
                  let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.end else {
                return nil
            }
            return (startOfLastMonth, endOfLastMonth)

        case .last7Days:
            return rangeForLast(days: 7, calendar: calendar, now: now)

        case .last30Days:
            return rangeForLast(days: 30, calendar: calendar, now: now)

        case .yearToDate:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let endOfToday = calendar.dateInterval(of: .day, for: now)?.end ?? now
            return (startOfYear, endOfToday)

        case .custom:
            guard let customStart = customStart,
                  let customEnd = customEnd,
                  customStart <= customEnd else {
                return nil
            }
            let startOfDay = calendar.startOfDay(for: customStart)
            let endOfDay = calendar.dateInterval(of: .day, for: customEnd)?.end ?? customEnd
            return (startOfDay, endOfDay)
        }
    }

    // Helper to compute start/end for last N days
    private func rangeForLast(days: Int, calendar: Calendar, now: Date) -> (start: Date, end: Date)? {
        guard let past = calendar.date(byAdding: .day, value: -days, to: now) else {
            return nil
        }
        let startOfDay = calendar.startOfDay(for: past)
        let endOfToday = calendar.dateInterval(of: .day, for: now)?.end ?? now
        return (startOfDay, endOfToday)
    }

    static let defaultFilter: DateRangeFilter = .allTime
}
