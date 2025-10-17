//
//  Category.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var color: String
    var symbolName: String

    @Relationship(deleteRule: .cascade, inverse: \Expense.category)
    var expenses: [Expense] = []

    init(name: String, color: String, symbolName: String) {
        self.name = name
        self.color = color
        self.symbolName = symbolName
    }
}
