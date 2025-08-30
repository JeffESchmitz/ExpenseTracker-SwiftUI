//
//  AddCategorySheet.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import SwiftUI
import SwiftData

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    
    // Edit mode support
    let category: Category?
    
    // Form state
    @State private var name = ""
    @State private var selectedColor = "blue"
    @State private var selectedSymbol = "tag.fill"
    @State private var showingSymbolPicker = false
    
    // Validation state
    @State private var nameError: String?
    
    private var isEditing: Bool {
        category != nil
    }
    
    private var isValid: Bool {
        !name.isEmpty && nameError == nil && !selectedColor.isEmpty && !selectedSymbol.isEmpty
    }
    
    init(category: Category? = nil) {
        self.category = category
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Category name", text: $name)
                            .onChange(of: name) { _, newValue in
                                validateName(newValue)
                            }
                        
                        if let error = nameError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Name")
                }
                
                Section {
                    ColorPalette(selectedColor: selectedColor) { color in
                        selectedColor = color
                    }
                } header: {
                    Text("Color")
                }
                
                Section {
                    VStack(spacing: 12) {
                        // Selected symbol preview
                        HStack {
                            Image(systemName: selectedSymbol)
                                .font(.title)
                                .foregroundStyle(colorForCategory(selectedColor))
                                .frame(width: 40)
                            
                            Text(selectedSymbol)
                                .font(.body)
                            
                            Spacer()
                            
                            Button("Change") {
                                showingSymbolPicker = true
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        }
                        
                        Button("Browse Symbols") {
                            showingSymbolPicker = true
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("Symbol")
                }
                
                // Preview section
                Section {
                    HStack {
                        Image(systemName: selectedSymbol)
                            .font(.title2)
                            .foregroundStyle(colorForCategory(selectedColor))
                            .frame(width: 30)
                        
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.body)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Update" : "Save") {
                        saveCategory()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingSymbolPicker) {
                SFSymbolPicker(selectedSymbol: selectedSymbol) { symbol in
                    selectedSymbol = symbol
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            setupInitialValues()
        }
    }
    
    private func setupInitialValues() {
        if let category = category {
            // Edit mode - populate with existing data
            name = category.name
            selectedColor = category.color
            selectedSymbol = category.symbolName
        } else {
            // Add mode - use defaults
            selectedColor = "blue"
            selectedSymbol = "tag.fill"
        }
        
        // Clear any previous validation errors
        nameError = nil
    }
    
    private func validateName(_ newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if name is empty
        if trimmedName.isEmpty {
            nameError = nil // Don't show error for empty field while typing
            return
        }
        
        // Check for uniqueness (case-insensitive)
        let existingNames = categories.map { $0.name.lowercased() }
        let isNameTaken: Bool
        
        if isEditing {
            // When editing, exclude the current category from uniqueness check
            isNameTaken = existingNames.filter { $0 != category?.name.lowercased() }.contains(trimmedName.lowercased())
        } else {
            isNameTaken = existingNames.contains(trimmedName.lowercased())
        }
        
        if isNameTaken {
            nameError = "A category with this name already exists"
        } else {
            nameError = nil
        }
    }
    
    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, nameError == nil else { return }
        
        if let existingCategory = category {
            // Update existing category
            existingCategory.name = trimmedName
            existingCategory.color = selectedColor
            existingCategory.symbolName = selectedSymbol
        } else {
            // Create new category
            let newCategory = Category(
                name: trimmedName,
                color: selectedColor,
                symbolName: selectedSymbol
            )
            modelContext.insert(newCategory)
        }
        
        do {
            try modelContext.save()
            
            // Success haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            dismiss()
        } catch {
            print("Failed to save category: \(error)")
        }
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
    AddCategorySheet()
}

#Preview("Edit Mode") {
    AddCategorySheet(
        category: Category(name: "Food", color: "orange", symbolName: "fork.knife")
    )
}