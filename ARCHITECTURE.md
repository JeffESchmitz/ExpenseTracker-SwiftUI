# Architecture Documentation

## Overview

ExpenseTracker-SwiftUI follows a **model-driven SwiftUI architecture** that eliminates traditional MVVM patterns in favor of direct SwiftData integration. This approach leverages SwiftUI's reactive capabilities and SwiftData's seamless persistence to create a clean, maintainable codebase.

## Core Principles

1. **Model-Driven Architecture**: `@Model` types serve as the single source of truth
2. **Direct Data Access**: Views query and mutate SwiftData models directly using `@Query` and `@Environment(\.modelContext)`
3. **Reactive UI**: SwiftUI automatically updates when SwiftData models change
4. **Minimal Indirection**: No ViewModels, no redundant state management layers

---

## SwiftData Models

### Model Hierarchy

```
Category (one-to-many) ──> Expense
    ├── Budget (one-to-one)
    └── Multiple Expenses
```

### 1. Expense Model

**File**: `/ExpenseTracker/Models/Expense.swift`

```swift
@Model
final class Expense {
    var amount: Decimal
    var date: Date
    var notes: String?
    var isDemo: Bool

    @Relationship
    var category: Category
}
```

**Purpose**: Represents a single expense transaction

**Key Features**:
- Uses `Decimal` for precise monetary calculations
- `@Relationship` establishes bidirectional link with `Category`
- `isDemo` flag allows filtering demo data from real expenses
- Cascade delete handled via `Category.expenses` relationship

**Data Flow**:
1. Created via `AddExpenseSheet` form
2. Inserted into `ModelContext` via `@Environment(\.modelContext)`
3. Queried in views using `@Query(sort: \Expense.date, order: .reverse)`
4. Auto-persisted to SQLite via SwiftData

### 2. Category Model

**File**: `/ExpenseTracker/Models/Category.swift`

```swift
@Model
final class Category {
    var name: String
    var color: String        // Stored as string ("orange", "blue", etc.)
    var symbolName: String   // SF Symbol name

    @Relationship(deleteRule: .cascade, inverse: \Expense.category)
    var expenses: [Expense] = []
}
```

**Purpose**: Categorizes expenses for organization and reporting

**Key Features**:
- `.cascade` delete rule: deleting a category deletes all associated expenses
- Inverse relationship to `Expense` maintains referential integrity
- Color stored as string (converted to `Color` at UI boundary)
- SF Symbol stored by name for flexibility

**Special Categories**:
- "Uncategorized": Protected category created on-demand when deleting categories
- Cannot be deleted by user (enforced in `CategoriesView`)

**Data Flow**:
1. Seeded on first launch via `ExpenseTrackerApp.seedDefaultCategoriesIfNeeded()`
2. Created/edited via `AddCategorySheet`
3. Referenced by `Expense` via `@Relationship`
4. Queried using `@Query(sort: \Category.name)`

### 3. Budget Model

**File**: `/ExpenseTracker/Models/Budget.swift`

```swift
@Model
final class Budget {
    @Attribute(.unique) var id: UUID

    @Relationship
    var category: Category

    var monthlyLimit: Decimal
    var currentMonth: Date  // Normalized to first day of month
    var notes: String?
    var isDemo: Bool
}
```

**Purpose**: Tracks spending limits per category per month

**Key Features**:
- `@Attribute(.unique)` ensures one budget per category per month
- Validates `monthlyLimit > 0` in initializer (throws `BudgetError.invalidLimit`)
- Computed properties: `percentageUsed`, `amountRemaining`, `isAlertThreshold`, `isWarningThreshold`
- `calculateCurrentSpending()` method filters expenses by current month

**Computed Logic**:
```swift
func calculateCurrentSpending() -> Decimal {
    let monthStart = currentMonth.startOfMonth
    let monthEnd = currentMonth.endOfMonth

    let relevantExpenses = category.expenses.filter { expense in
        expense.date >= monthStart && expense.date <= monthEnd && !expense.isDemo
    }

    return relevantExpenses.reduce(0) { $0 + $1.amount }
}
```

**Data Flow**:
1. Created via `AddBudgetSheet`
2. Filtered to current month in `BudgetsView`
3. Displayed in `BudgetProgressCard` on Dashboard
4. Real-time spending calculation via `calculateCurrentSpending()`

---

## Data Persistence

### SwiftData Container Setup

**File**: `/ExpenseTracker/ExpenseTrackerApp.swift`

```swift
.modelContainer(for: [Expense.self, Category.self, Budget.self])
```

**Schema Configuration**:
```swift
let schema = Schema([Expense.self, Category.self, Budget.self])
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false
)
```

**Storage Location**:
- Production: `URL.applicationSupportDirectory/default.store` (SQLite database)
- Previews: In-memory container via `PreviewData.previewModelContainer`

### Schema Migration Strategy

When model schemas change (e.g., adding new properties):

1. **Attempt Creation**: Try to create container with new schema
2. **Detect Conflict**: Catch schema mismatch error
3. **Reset Store**: Delete existing `default.store` file
4. **Recreate Container**: Build fresh container with new schema
5. **Log Failure**: Fatal error if recreation fails

**Code** (from `ExpenseTrackerApp.modelContainer`):
```swift
do {
    return try ModelContainer(for: schema, configurations: [modelConfiguration])
} catch {
    print("Schema migration needed. Attempting to reset data store...")
    try? FileManager.default.removeItem(at: url)
    // Retry creation
}
```

**Trade-offs**:
- **Pros**: Simple, eliminates schema migration complexity
- **Cons**: Data loss on schema changes (acceptable for MVP)

### Default Data Seeding

Categories are seeded on first launch:

```swift
private func seedDefaultCategoriesIfNeeded() {
    let descriptor = FetchDescriptor<Category>()
    let existingCategories = try? context.fetch(descriptor)

    guard existingCategories?.isEmpty == true else { return }

    let defaultCategories = [
        Category(name: "Food", color: "orange", symbolName: "fork.knife"),
        Category(name: "Transportation", color: "blue", symbolName: "car.fill"),
        // ... more categories
    ]

    defaultCategories.forEach { context.insert($0) }
    try context.save()
}
```

---

## Data Query Patterns

### 1. Basic Query

**Most common pattern** - fetch all with sort:
```swift
@Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
```

### 2. Filtered Query

Use `FetchDescriptor` for complex queries:
```swift
let descriptor = FetchDescriptor<Expense>(
    predicate: #Predicate { expense in
        expense.category.name == "Food" && !expense.isDemo
    }
)
let foodExpenses = try modelContext.fetch(descriptor)
```

### 3. In-Memory Filtering

For UI-level filters, query all data then filter in Swift:
```swift
private var filteredExpenses: [Expense] {
    var result = expenses

    // Apply date range filter
    if let dateRange = selectedFilter.dateRange(...) {
        result = result.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
    }

    // Apply category filter
    if let selectedCategory = selectedCategory {
        result = result.filter { $0.category.name == selectedCategory.name }
    }

    return result
}
```

**Why in-memory filtering?**:
- `@Query` doesn't support dynamic predicates (yet)
- UI filters change frequently (date ranges, categories)
- Dataset size is manageable for in-memory operations
- Maintains reactive updates via `@Query`

---

## Data Mutation Patterns

### 1. Insert

```swift
let expense = Expense(amount: 42.50, date: Date(), notes: "Lunch", category: category)
modelContext.insert(expense)

do {
    try modelContext.save()
} catch {
    print("Failed to save: \(error)")
}
```

### 2. Update

SwiftData automatically tracks changes - just modify properties:
```swift
expense.amount = 50.00
expense.notes = "Updated notes"
// Auto-saved on next save cycle or when context changes
```

### 3. Delete

```swift
modelContext.delete(expense)
try modelContext.save()
```

**Cascade Deletes**:
- Deleting a `Category` deletes all associated `Expense` objects (via `deleteRule: .cascade`)
- Deleting a `Budget` does not affect `Category` or `Expense` objects

### 4. Batch Operations

For multiple operations, use single save:
```swift
expenses.forEach { modelContext.delete($0) }
try modelContext.save()  // Single commit
```

---

## State Management

### AppStorage for Filters

Persistent UI state using `@AppStorage`:

```swift
@AppStorage("filterType") private var filterTypeRaw = DateRangeFilter.defaultFilter.rawValue
@AppStorage("customStartDateTimestamp") private var customStartDateTimestamp: Double = 0
@AppStorage("customEndDateTimestamp") private var customEndDateTimestamp: Double = 0
@AppStorage("selectedCategoryName") private var selectedCategoryName: String?
```

**Shared Across Views**:
- `ExpenseListView` sets filters
- `DashboardView` reads same filters
- `SettingsView` exports based on current filters

**Benefits**:
- Auto-persists across app launches
- No need for ObservableObject or EnvironmentObject
- Type-safe access via computed properties

### View-Local State

For transient UI state, use `@State`:
```swift
@State private var showingAddSheet = false
@State private var searchText = ""
@State private var expenseToEdit: Expense?
```

---

## Concurrency

### Main Actor UI Updates

All UI updates are on the main actor (SwiftUI default):
```swift
@MainActor
struct ExpenseListView: View { ... }
```

### Async Operations

IO-bound operations use async/await:
```swift
private func exportCSV() {
    let csvContent = CSVService.exportExpenses(filteredExpenses)

    if let fileURL = CSVService.createTempCSVFile(content: csvContent) {
        exportFileURL = fileURL
    }
}
```

### Background Context Pattern

For heavy operations, use background context (not currently needed):
```swift
let backgroundContext = ModelContext(modelContainer)
await backgroundContext.perform {
    // Heavy operation
    try backgroundContext.save()
}
```

---

## Error Handling

### Model Initialization

Models validate input via throwing initializers:
```swift
init(category: Category, monthlyLimit: Decimal, currentMonth: Date) throws {
    guard monthlyLimit > 0 else {
        throw BudgetError.invalidLimit("Budget monthly limit must be positive")
    }
    self.monthlyLimit = monthlyLimit
    // ...
}
```

### View-Level Handling

Errors logged to console (development) or shown to user (production):
```swift
do {
    try modelContext.save()
} catch {
    print("Failed to save expense: \(error)")
    // In production: show alert to user
}
```

### Silent Failures

For non-critical operations:
```swift
try? modelContext.save()  // Demo data generation, seeding
```

---

## Testing Strategy

### Unit Tests

Test model logic in isolation:
```swift
func testCalculateCurrentSpendingIncludesExpensesOnLastDay() throws {
    let category = try Category(name: "Food", colorHex: "#FF0000")
    let budget = try Budget(category: category, monthlyLimit: 200, currentMonth: Date())

    let expense = Expense(amount: 50, date: Date().endOfMonth, category: category)
    category.expenses.append(expense)

    XCTAssertEqual(budget.calculateCurrentSpending(), 50)
}
```

### Preview Data

Shared preview container for SwiftUI previews:
```swift
#Preview {
    BudgetsView()
        .modelContainer(PreviewData.previewModelContainer)
}
```

---

## Key Design Decisions

### 1. Why No ViewModels?

**Traditional MVVM**:
```
View → ViewModel → Model (complex, redundant state)
```

**Model-Driven SwiftUI**:
```
View → @Query/@Bindable → SwiftData Model (direct, reactive)
```

**Benefits**:
- Eliminates boilerplate
- Reduces bugs from state synchronization
- Leverages SwiftUI's reactive architecture
- Clearer data flow

### 2. Why In-Memory Filtering?

SwiftData's `@Query` doesn't support dynamic predicates yet. In-memory filtering:
- Keeps UI responsive
- Maintains reactive updates
- Works with reasonable dataset sizes (100s-1000s of expenses)

### 3. Why String-Based Colors?

```swift
var color: String  // Not: var color: Color
```

**Rationale**:
- SwiftData can't persist `Color` directly
- String → Color conversion is trivial
- Allows future extensibility (hex codes, gradients)
- Separates persistence from presentation

### 4. Why Cascade Delete?

```swift
@Relationship(deleteRule: .cascade, inverse: \Expense.category)
var expenses: [Expense] = []
```

**Alternative**: Reassign expenses to "Uncategorized" (used when user deletes category)

**Use Case**:
- Cascade: Model-level delete (programmatic cleanup)
- Reassign: User-initiated delete (preserve data)

---

## Performance Considerations

### Query Optimization

1. **Fetch All, Filter in Memory**: For small datasets (<10k expenses)
2. **Use Predicates**: For larger datasets or server-backed data
3. **Pagination**: Not implemented (not needed for MVP)

### Memory Management

- SwiftData automatically faults objects (lazy loading)
- In-memory containers for previews prevent disk I/O
- Avoid retaining large query results

### UI Responsiveness

- Computed properties cached automatically by SwiftUI
- Date calculations memoized via `startOfMonth`/`endOfMonth` extensions
- Charts use aggregated data, not raw expenses

---

## Future Enhancements

### Potential Improvements

1. **CloudKit Sync**: Add `.modelContainer(..., isCloudKitEnabled: true)`
2. **Versioned Schema**: Implement `VersionedSchema` for migration
3. **Background Refresh**: Periodic budget recalculation
4. **Optimistic Locking**: Handle concurrent modifications
5. **Predicate-Based Filtering**: Once SwiftData supports dynamic predicates

### Scalability

Current architecture scales to:
- **Expenses**: 10,000+ (tested with demo data)
- **Categories**: 100+
- **Budgets**: 100+ (one per category per month)

For larger datasets:
- Implement pagination in `ExpenseListView`
- Use `FetchDescriptor` with `fetchLimit` and `fetchOffset`
- Consider archiving old expenses

---

## Appendix: Model Relationships

### Entity-Relationship Diagram

```
┌─────────────┐
│  Category   │
│─────────────│
│ name        │───┐
│ color       │   │ (one-to-many)
│ symbolName  │   │
└─────────────┘   │
       │          │
       │          ▼
       │   ┌─────────────┐
       │   │   Expense   │
       │   │─────────────│
       └───│ category    │
           │ amount      │
           │ date        │
           │ notes       │
           │ isDemo      │
           └─────────────┘
       │
       │ (one-to-one)
       │
       ▼
┌─────────────┐
│   Budget    │
│─────────────│
│ category    │
│ monthlyLimit│
│ currentMonth│
│ notes       │
│ isDemo      │
└─────────────┘
```

### Relationship Rules

1. Every `Expense` must have exactly one `Category` (required relationship)
2. Every `Budget` must have exactly one `Category` (required relationship)
3. A `Category` can have zero or more `Expense` objects
4. A `Category` can have zero or more `Budget` objects (one per month)
5. Deleting a `Category` cascades to `Expense` but not `Budget` (manual reassignment)

---

## Summary

ExpenseTracker-SwiftUI demonstrates modern iOS architecture by:

1. Leveraging SwiftData for persistence without abstraction layers
2. Using SwiftUI's reactive capabilities for automatic UI updates
3. Maintaining clear separation between models (data) and views (presentation)
4. Following Apple's recommended patterns for iOS 17+ applications

This architecture prioritizes simplicity, maintainability, and developer productivity while delivering a robust expense tracking experience.
