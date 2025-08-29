//
//  DashboardView.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "chart.pie.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Dashboard")
                    .font(.title2)
                Text("Coming soon...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    DashboardView()
}