//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
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
