//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
//

import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    seedDefaultCategoriesIfNeeded()
                }
        }
        .modelContainer(for: [Expense.self, Category.self])
    }
    
    private func seedDefaultCategoriesIfNeeded() {
        let context = ModelContext(modelContainer)
        
        // Check if categories already exist
        let descriptor = FetchDescriptor<Category>()
        let existingCategories = try? context.fetch(descriptor)
        
        guard existingCategories?.isEmpty == true else { return }
        
        // Create default categories
        let defaultCategories = [
            Category(name: "Food", color: "orange", symbolName: "fork.knife"),
            Category(name: "Transportation", color: "blue", symbolName: "car.fill"),
            Category(name: "Entertainment", color: "purple", symbolName: "tv.fill"),
            Category(name: "Shopping", color: "pink", symbolName: "bag.fill"),
            Category(name: "Bills", color: "red", symbolName: "doc.text.fill"),
            Category(name: "Other", color: "gray", symbolName: "ellipsis.circle.fill")
        ]
        
        for category in defaultCategories {
            context.insert(category)
        }
        
        try? context.save()
    }
    
    private var modelContainer: ModelContainer {
        do {
            return try ModelContainer(for: Expense.self, Category.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
