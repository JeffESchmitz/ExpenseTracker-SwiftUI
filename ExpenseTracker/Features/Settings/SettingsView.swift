//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "gear")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Settings")
                    .font(.title2)
                Text("Coming soon...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}