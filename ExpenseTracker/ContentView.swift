//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ExpenseListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Expenses")
                }

            DashboardView()
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("Dashboard")
                }

            BudgetsView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Budgets")
                }

            CategoriesView()
                .tabItem {
                    Image(systemName: "tag")
                    Text("Categories")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    ContentView()
}
