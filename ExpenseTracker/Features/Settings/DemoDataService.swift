//
//  DemoDataService.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/30/25.
//

import Foundation
import SwiftData

struct DemoDataService {
    
    static func insertDemoData(modelContext: ModelContext, categories: [Category]) -> Int {
        // Ensure we don't double-seed
        let existingDemoCount = countDemoExpenses(modelContext: modelContext)
        if existingDemoCount > 0 {
            return existingDemoCount
        }
        
        guard !categories.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let expenseCount = Int.random(in: 80...120)
        
        // Sample notes for realistic variety
        let sampleNotes = [
            "Coffee and pastry",
            "Grocery shopping",
            "Gas station fill-up",
            "Restaurant dinner",
            "Online shopping",
            "Pharmacy pickup",
            "Movie tickets",
            "Lunch with colleagues",
            "Weekend groceries",
            "Car maintenance",
            "Streaming subscription",
            "Phone bill",
            "Internet service",
            "Gym membership",
            "Haircut",
            "Book purchase",
            "Home supplies",
            "Pet food",
            "Clothing purchase",
            "Birthday gift",
            nil, nil, nil // Some expenses without notes
        ]
        
        var createdExpenses = 0
        
        for _ in 0..<expenseCount {
            // Random date in last 6-12 months
            let monthsBack = Int.random(in: 1...12)
            let daysBack = Int.random(in: 0...30)
            
            guard let baseDate = calendar.date(byAdding: .month, value: -monthsBack, to: now),
                  let expenseDate = calendar.date(byAdding: .day, value: -daysBack, to: baseDate) else {
                continue
            }
            
            // Random category
            let randomCategory = categories.randomElement()!
            
            // Realistic amount based on category
            let amount = generateRealisticAmount(for: randomCategory.name)
            
            // Random notes (some expenses have no notes)
            let notes = sampleNotes.randomElement() ?? nil
            
            let expense = Expense(
                amount: amount,
                date: expenseDate,
                notes: notes,
                category: randomCategory,
                isDemo: true
            )
            
            modelContext.insert(expense)
            createdExpenses += 1
        }
        
        do {
            try modelContext.save()
            return createdExpenses
        } catch {
            print("Failed to save demo expenses: \(error)")
            return 0
        }
    }
    
    static func removeDemoData(modelContext: ModelContext) -> Int {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.isDemo == true }
        )
        
        do {
            let demoExpenses = try modelContext.fetch(fetchDescriptor)
            let count = demoExpenses.count
            
            for expense in demoExpenses {
                modelContext.delete(expense)
            }
            
            try modelContext.save()
            return count
        } catch {
            print("Failed to remove demo expenses: \(error)")
            return 0
        }
    }
    
    static func countDemoExpenses(modelContext: ModelContext) -> Int {
        let fetchDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.isDemo == true }
        )
        
        do {
            let demoExpenses = try modelContext.fetch(fetchDescriptor)
            return demoExpenses.count
        } catch {
            print("Failed to count demo expenses: \(error)")
            return 0
        }
    }
    
    private static func generateRealisticAmount(for categoryName: String) -> Decimal {
        let categoryLower = categoryName.lowercased()
        
        switch categoryLower {
        case let name where name.contains("food") || name.contains("restaurant") || name.contains("dining"):
            return Decimal(Double.random(in: 8.0...45.0))
            
        case let name where name.contains("transport") || name.contains("gas") || name.contains("fuel"):
            return Decimal(Double.random(in: 25.0...85.0))
            
        case let name where name.contains("shopping") || name.contains("retail"):
            return Decimal(Double.random(in: 15.0...120.0))
            
        case let name where name.contains("entertainment") || name.contains("movie") || name.contains("game"):
            return Decimal(Double.random(in: 10.0...35.0))
            
        case let name where name.contains("health") || name.contains("medical") || name.contains("pharmacy"):
            return Decimal(Double.random(in: 15.0...75.0))
            
        case let name where name.contains("utility") || name.contains("bill") || name.contains("subscription"):
            return Decimal(Double.random(in: 25.0...150.0))
            
        case let name where name.contains("travel") || name.contains("hotel"):
            return Decimal(Double.random(in: 50.0...300.0))
            
        case let name where name.contains("education") || name.contains("book"):
            return Decimal(Double.random(in: 20.0...80.0))
            
        default:
            return Decimal(Double.random(in: 10.0...100.0))
        }
    }
}