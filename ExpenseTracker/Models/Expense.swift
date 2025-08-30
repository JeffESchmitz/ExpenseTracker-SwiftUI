//
//  Expense.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import Foundation
import SwiftData

@Model
final class Expense {
    var amount: Decimal
    var date: Date
    var notes: String?
    var isDemo: Bool
    
    @Relationship
    var category: Category
    
    init(amount: Decimal, date: Date, notes: String? = nil, category: Category, isDemo: Bool = false) {
        self.amount = amount
        self.date = date
        self.notes = notes
        self.category = category
        self.isDemo = isDemo
    }
}