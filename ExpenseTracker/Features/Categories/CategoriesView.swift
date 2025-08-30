//
//  CategoriesView.swift
//  ExpenseTracker
//
//  Created by Jeffrey.Schmitz2 on 8/29/25.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query(sort: \Category.name) private var categories: [Category]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var categoryToDelete: Category?
    @State private var categoryToEdit: Category?
    
    private var uncategorizedCategory: Category? {
        categories.first { $0.name.lowercased() == "uncategorized" }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No categories",
                        systemImage: "tag",
                        description: Text("Add your first category to get started.")
                    )
                } else {
                    List {
                        ForEach(categories) { category in
                            CategoryRowView(category: category)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    categoryToEdit = category
                                    showingEditSheet = true
                                }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityLabel("\(category.name) category")
                                .accessibilityValue("Color: \(category.color), Symbol: \(category.symbolName)")
                        }
                        .onDelete(perform: deleteCategories)
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCategorySheet()
            }
            .sheet(isPresented: $showingEditSheet) {
                if let categoryToEdit = categoryToEdit {
                    AddCategorySheet(category: categoryToEdit)
                }
            }
            .alert("Delete Category", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let category = categoryToDelete {
                    Text("Delete '\(category.name)'? Existing expenses will be reassigned to 'Uncategorized'.")
                }
            }
        }
        .onAppear {
            ensureUncategorizedExists()
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            
            // Cannot delete "Uncategorized" category
            if category.name.lowercased() == "uncategorized" {
                continue
            }
            
            categoryToDelete = category
            showingDeleteConfirmation = true
            break // Only handle first deletion at a time
        }
    }
    
    private func confirmDelete() {
        guard let categoryToDelete = categoryToDelete else { return }
        
        // Ensure "Uncategorized" category exists before reassigning
        ensureUncategorizedExists()
        
        guard let uncategorized = uncategorizedCategory else {
            print("Error: Could not find or create Uncategorized category")
            return
        }
        
        // Reassign all expenses from deleted category to "Uncategorized"
        let fetchDescriptor = FetchDescriptor<Expense>()
        
        do {
            let allExpenses = try modelContext.fetch(fetchDescriptor)
            let expensesToReassign = allExpenses.filter { $0.category.name == categoryToDelete.name }
            
            for expense in expensesToReassign {
                expense.category = uncategorized
            }
            
            // Delete the category
            modelContext.delete(categoryToDelete)
            
            try modelContext.save()
            
            // Success haptic
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        } catch {
            print("Failed to delete category and reassign expenses: \(error)")
        }
        
        self.categoryToDelete = nil
    }
    
    private func ensureUncategorizedExists() {
        // Check if "Uncategorized" category already exists
        if uncategorizedCategory != nil {
            return
        }
        
        // Create "Uncategorized" category if it doesn't exist
        let uncategorized = Category(
            name: "Uncategorized",
            color: "gray",
            symbolName: "questionmark.circle.fill"
        )
        
        modelContext.insert(uncategorized)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to create Uncategorized category: \(error)")
        }
    }
}

struct CategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 12) {
            // Color swatch
            Circle()
                .fill(colorForCategory(category.color))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 1)
                )
            
            // Symbol
            Image(systemName: category.symbolName)
                .font(.title3)
                .foregroundStyle(colorForCategory(category.color))
                .frame(width: 24)
            
            // Category name
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            // Non-deletable indicator for "Uncategorized"
            if category.name.lowercased() == "uncategorized" {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Cannot be deleted")
            }
        }
        .padding(.vertical, 2)
    }
    
    private func colorForCategory(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "pink": return .pink
        case "red": return .red
        case "purple": return .purple
        case "teal": return .teal
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "brown": return .brown
        case "gray": return .gray
        default: return .blue
        }
    }
}

#Preview {
    CategoriesView()
}