//
//  CategoriesView.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
//

import SwiftUI

struct CategoriesView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "tag.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Categories")
                    .font(.title2)
                Text("Coming soon...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Categories")
        }
    }
}

#Preview {
    CategoriesView()
}