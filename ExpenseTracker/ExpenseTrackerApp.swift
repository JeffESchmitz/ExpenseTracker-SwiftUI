//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
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
        .modelContainer(for: [Expense.self, Category.self, Budget.self])
    }
    private func seedDefaultCategoriesIfNeeded() {
        let context = ModelContext(modelContainer)

        // Check if categories already exist
        let descriptor = FetchDescriptor<Category>()
        let existingCategories = try? context.fetch(descriptor)

        print("🌱 App: Existing categories count: \(existingCategories?.count ?? -1)")

        guard existingCategories?.isEmpty == true else {
            print("🌱 App: Categories already exist, skipping seed")
            return
        }

        // Create default categories
        let defaultCategories = [
            Category(name: "Food", color: "orange", symbolName: "fork.knife"),
            Category(name: "Transportation", color: "blue", symbolName: "car.fill"),
            Category(name: "Entertainment", color: "purple", symbolName: "tv.fill"),
            Category(name: "Shopping", color: "pink", symbolName: "bag.fill"),
            Category(name: "Bills", color: "red", symbolName: "doc.text.fill"),
            Category(name: "Other", color: "gray", symbolName: "ellipsis.circle.fill")
        ]

        print("🌱 App: Creating \(defaultCategories.count) default categories")

        for category in defaultCategories {
            context.insert(category)
        }

        do {
            try context.save()
            print("🌱 App: Successfully seeded default categories")
        } catch {
            print("🌱 App: Failed to save default categories: \(error)")
        }
    }

    private var modelContainer: ModelContainer {
        do {
            let schema = Schema([
                Expense.self,
                Category.self,
                Budget.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If there's a schema conflict, try to create a fresh container
            // This will happen when we add new fields to existing models
            print("Schema migration needed. Attempting to reset data store...")

            // Try to delete the old store file and create new one
            let url = URL.applicationSupportDirectory.appendingPathComponent("default.store")
            try? FileManager.default.removeItem(at: url)

            do {
                let schema = Schema([
                    Expense.self,
                    Category.self,
                    Budget.self
                ])
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Failed to create ModelContainer even after reset: \(error)")
            }
        }
    }
}
