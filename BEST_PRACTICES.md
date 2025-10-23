# Best Practices Guide

## Overview

This guide documents the coding standards, patterns, and best practices for ExpenseTracker-SwiftUI. Following these guidelines ensures consistency, maintainability, and quality across the codebase.

---

## Table of Contents

1. [SwiftUI + SwiftData Patterns](#swiftui--swiftdata-patterns)
2. [Architecture Patterns](#architecture-patterns)
3. [Code Organization](#code-organization)
4. [Naming Conventions](#naming-conventions)
5. [State Management](#state-management)
6. [Data Flow](#data-flow)
7. [Error Handling](#error-handling)
8. [Performance](#performance)
9. [Testing](#testing)
10. [Accessibility](#accessibility)

---

## SwiftUI + SwiftData Patterns

### 1. Model-Driven Views

**DO**: Use `@Query` to fetch data directly in views

```swift
struct ExpenseListView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    var body: some View {
        List(expenses) { expense in
            ExpenseRowView(expense: expense)
        }
    }
}
```

**DON'T**: Create ViewModels or intermediate state layers

```swift
// ❌ Avoid this pattern
class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []

    func fetchExpenses() {
        // Redundant with @Query
    }
}
```

**Rationale**: SwiftData + SwiftUI provides automatic reactivity. Adding ViewModels introduces unnecessary complexity and potential for state synchronization bugs.

---

### 2. Use @Bindable for Inline Editing

**DO**: Use `@Bindable` when editing models in forms

```swift
struct EditExpenseSheet: View {
    @Bindable var expense: Expense

    var body: some View {
        Form {
            TextField("Amount", value: $expense.amount, format: .currency(code: "USD"))
            DatePicker("Date", selection: $expense.date)
        }
    }
}
```

**DON'T**: Copy model properties to `@State`

```swift
// ❌ Avoid this pattern
struct EditExpenseSheet: View {
    let expense: Expense
    @State private var amount: Decimal
    @State private var date: Date

    init(expense: Expense) {
        self.expense = expense
        _amount = State(initialValue: expense.amount)
        _date = State(initialValue: expense.date)
    }

    // Must manually sync back to model
}
```

**Rationale**: `@Bindable` provides two-way binding directly to SwiftData models, eliminating manual synchronization.

---

### 3. Filter in Memory for UI Filters

**DO**: Use computed properties for UI-level filtering

```swift
@Query private var expenses: [Expense]

private var filteredExpenses: [Expense] {
    var result = expenses

    if let dateRange = selectedFilter.dateRange() {
        result = result.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
    }

    if let category = selectedCategory {
        result = result.filter { $0.category.name == category.name }
    }

    return result
}
```

**DON'T**: Use `FetchDescriptor` for dynamic UI filters (yet)

```swift
// ❌ Over-engineering for current SwiftData limitations
@Query private var expenses: [Expense]

func applyFilter(_ filter: DateRangeFilter) {
    let descriptor = FetchDescriptor<Expense>(
        predicate: #Predicate { /* complex dynamic predicate */ }
    )
    // SwiftData doesn't support dynamic predicates in @Query yet
}
```

**Rationale**: SwiftData's `@Query` doesn't support dynamic predicates. In-memory filtering is performant for typical dataset sizes (<10k items) and maintains reactive updates.

---

### 4. Use ModelContext for Mutations

**DO**: Access `ModelContext` via `@Environment`

```swift
@Environment(\.modelContext) private var modelContext

func addExpense() {
    let expense = Expense(amount: 42.50, date: Date(), category: category)
    modelContext.insert(expense)

    do {
        try modelContext.save()
    } catch {
        print("Failed to save: \(error)")
    }
}
```

**DON'T**: Modify arrays directly

```swift
// ❌ Does not persist to SwiftData
@Query private var expenses: [Expense]

func addExpense() {
    let expense = Expense(...)
    expenses.append(expense)  // Won't persist!
}
```

**Rationale**: Only `ModelContext` operations persist to SwiftData. Direct array modifications are lost.

---

## Architecture Patterns

### 1. No ViewModels

**DO**: Build model-driven views

```swift
struct BudgetsView: View {
    @Query private var budgets: [Budget]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List(budgets) { budget in
            BudgetRowView(budget: budget)
        }
    }
}
```

**DON'T**: Create MVVM structure

```swift
// ❌ Avoid this pattern in this project
class BudgetsViewModel: ObservableObject {
    @Published var budgets: [Budget] = []

    func fetchBudgets() { /* ... */ }
    func addBudget(_ budget: Budget) { /* ... */ }
}
```

**Rationale**: Model-driven SwiftUI eliminates boilerplate while maintaining clarity and testability.

---

### 2. Services for Business Logic

**DO**: Use static service structs for complex operations

```swift
struct CSVService {
    static func exportExpenses(_ expenses: [Expense]) -> String {
        // CSV generation logic
    }

    static func importCSV(from url: URL, into context: ModelContext) -> ImportResult {
        // CSV import logic
    }
}

// Usage
let csvContent = CSVService.exportExpenses(expenses)
```

**DON'T**: Put business logic in views

```swift
// ❌ View should not contain CSV generation logic
struct ExpenseListView: View {
    func exportCSV() {
        var csv = "date,amount,category,notes\n"
        for expense in expenses {
            // 50 lines of CSV formatting...
        }
    }
}
```

**Rationale**: Services separate business logic from presentation, improving testability and reusability.

---

### 3. Extract Complex Computed Properties

**DO**: Break down complex calculations

```swift
private var monthlyTrendData: (amount: Decimal, percentage: Double)? {
    guard let previousExpenses = previousPeriodExpenses else { return nil }
    return calculateTrend(current: currentAmount, previous: previousExpenses)
}

private var previousPeriodExpenses: [Expense]? {
    guard let dateRange = selectedFilter.previousPeriodRange() else { return nil }
    return expenses.filter { $0.date.isBetween(dateRange.start, and: dateRange.end) }
}

private func calculateTrend(current: Decimal, previous: [Expense]) -> (Decimal, Double) {
    let previousAmount = previous.reduce(0) { $0 + $1.amount }
    let difference = current - previousAmount
    let percentage = (difference / previousAmount) * 100
    return (difference, percentage)
}
```

**DON'T**: Create monolithic computed properties

```swift
// ❌ Hard to read and maintain
private var monthlyTrendData: (amount: Decimal, percentage: Double)? {
    switch selectedFilter {
    case .thisMonth:
        guard let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()),
              let range = Calendar.current.dateInterval(of: .month, for: lastMonth) else {
            return nil
        }
        let previousExpenses = expenses.filter { $0.date >= range.start && $0.date <= range.end }
        let previousAmount = previousExpenses.reduce(0) { $0 + $1.amount }
        let currentAmount = /* ... */
        let difference = currentAmount - previousAmount
        let percentage = previousAmount > 0 ? (difference / previousAmount) * 100 : 0
        return (difference, percentage)
    // ... 50 more lines for other cases
    }
}
```

**Rationale**: Smaller, focused functions are easier to understand, test, and debug.

---

## Code Organization

### 1. File Structure

**DO**: Organize files by feature

```
Features/
├── Expenses/
│   ├── ExpenseListView.swift       # Main view
│   ├── ExpenseRowView.swift        # Component
│   ├── AddExpenseSheet.swift       # Sheet
│   ├── DateRangeFilter.swift       # Model/Enum
│   └── ExpenseListView+Debug.swift # Extensions
```

**DON'T**: Organize by type

```
// ❌ Hard to navigate
Views/
├── ExpenseListView.swift
├── DashboardView.swift
├── BudgetsView.swift
Sheets/
├── AddExpenseSheet.swift
├── AddBudgetSheet.swift
Components/
├── ExpenseRowView.swift
├── BudgetRowView.swift
```

**Rationale**: Feature-based organization makes it easy to find related code and understand feature boundaries.

---

### 2. View Composition

**DO**: Extract large views into components

```swift
// ExpenseListView.swift
struct ExpenseListView: View {
    var body: some View {
        NavigationStack {
            Group {
                if filteredExpenses.isEmpty {
                    emptyStateView
                } else {
                    expenseListContent
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        // Empty state logic
    }

    @ViewBuilder
    private var expenseListContent: some View {
        // List content
    }
}
```

**DON'T**: Create monolithic views

```swift
// ❌ 500+ lines in single body property
struct ExpenseListView: View {
    var body: some View {
        NavigationStack {
            Group {
                if filteredExpenses.isEmpty {
                    if expenses.isEmpty {
                        ContentUnavailableView(...)
                    } else if shouldShowNoResultsForFilters {
                        VStack {
                            ContentUnavailableView(...)
                            VStack {
                                Button(...) { /* ... */ }
                                Button(...) { /* ... */ }
                            }
                        }
                    } else {
                        ContentUnavailableView.search
                    }
                } else {
                    VStack {
                        // 100 more lines...
                    }
                }
            }
            // 200 more lines of modifiers...
        }
    }
}
```

**Rationale**: Smaller views are easier to understand, preview, and test.

---

### 3. Group Related State

**DO**: Use structs to group related state

```swift
struct FilterState {
    var dateFilter: DateRangeFilter = .allTime
    var categoryName: String?
    var searchText: String = ""
    var customStartDate: Date?
    var customEndDate: Date?
}

@State private var filterState = FilterState()
```

**DON'T**: Scatter related `@State` properties

```swift
// ❌ Hard to manage
@State private var filterType: DateRangeFilter = .allTime
@State private var selectedCategoryName: String?
@State private var searchText = ""
@State private var customStartDate: Date?
@State private var customEndDate: Date?
// ... spread across 100 lines
```

**Rationale**: Grouped state is easier to pass around, reset, and understand.

---

## Naming Conventions

### 1. Boolean Properties

**DO**: Use `is`, `has`, `should` prefixes

```swift
var isEmpty: Bool
var hasActiveFilters: Bool
var shouldShowNoResults: Bool
var isAlertThreshold: Bool
```

**DON'T**: Use ambiguous names

```swift
// ❌ Unclear
var empty: Bool
var filters: Bool
var noResults: Bool
```

---

### 2. Action Methods

**DO**: Use verb-noun format

```swift
func addExpense()
func deleteExpense(_ expense: Expense)
func exportCSV()
func calculateCurrentSpending() -> Decimal
```

**DON'T**: Use noun-only names

```swift
// ❌ Unclear
func expense()
func csv()
func spending() -> Decimal
```

---

### 3. Computed Properties vs Methods

**DO**: Use computed properties for queries/calculations

```swift
var filteredExpenses: [Expense] { /* filter logic */ }
var totalAmount: Decimal { /* sum logic */ }
var isEmpty: Bool { expenses.isEmpty }
```

**DO**: Use methods for actions/mutations

```swift
func addExpense()
func deleteExpense(_ expense: Expense)
func exportCSV()
```

**Rule of Thumb**: If it changes state or performs an action, use a method. If it computes a value, use a computed property.

---

## State Management

### 1. Use @AppStorage for Persistent UI State

**DO**: Persist filters, preferences, and settings

```swift
@AppStorage("filterType") private var filterTypeRaw = DateRangeFilter.defaultFilter.rawValue
@AppStorage("demoModeEnabled") private var demoModeEnabled = false
@AppStorage("dashboardTimeRange") private var timeRangeRaw = DashboardTimeRange.twelveMonths.rawValue
```

**DON'T**: Use UserDefaults directly

```swift
// ❌ More boilerplate, less reactive
func saveFilter(_ filter: DateRangeFilter) {
    UserDefaults.standard.set(filter.rawValue, forKey: "filterType")
}

func loadFilter() -> DateRangeFilter {
    let raw = UserDefaults.standard.string(forKey: "filterType") ?? ""
    return DateRangeFilter(rawValue: raw) ?? .allTime
}
```

**Rationale**: `@AppStorage` provides automatic persistence and SwiftUI reactivity with minimal code.

---

### 2. Use @State for Transient UI State

**DO**: Use `@State` for temporary UI state

```swift
@State private var showingAddSheet = false
@State private var searchText = ""
@State private var selectedItem: Item?
```

**DON'T**: Persist transient state

```swift
// ❌ No need to persist
@AppStorage("showingAddSheet") private var showingAddSheet = false
```

**Rationale**: Transient state (sheets, selections, search) should reset between launches.

---

### 3. Share State via @AppStorage

**DO**: Share filters across views via `@AppStorage`

```swift
// ExpenseListView writes
@AppStorage("filterType") private var filterTypeRaw = ...

// DashboardView reads
@AppStorage("filterType") private var filterTypeRaw = ...
```

**DON'T**: Create complex shared state objects

```swift
// ❌ Over-engineering for simple state sharing
class AppState: ObservableObject {
    @Published var filterType: DateRangeFilter = .allTime
}

@EnvironmentObject var appState: AppState
```

**Rationale**: `@AppStorage` provides automatic syncing across views with no additional plumbing.

---

## Data Flow

### 1. Unidirectional Data Flow

**Pattern**:
```
User Action → View → ModelContext.insert/update/delete → SwiftData
    ↑                                                         ↓
    └─────────────── UI Update ←── @Query observes ──────────┘
```

**Example**:
```swift
func addExpense() {
    // 1. Create model
    let expense = Expense(amount: amount, date: date, category: category)

    // 2. Insert into context
    modelContext.insert(expense)

    // 3. Save
    try modelContext.save()

    // 4. SwiftData notifies @Query
    // 5. SwiftUI re-renders view
}
```

**Rationale**: Unidirectional flow is predictable and easier to debug.

---

### 2. Pass Models Down, Not Data

**DO**: Pass model objects to child views

```swift
ForEach(expenses) { expense in
    ExpenseRowView(expense: expense)
}
```

**DON'T**: Extract properties and pass individually

```swift
// ❌ Loses object identity and reactivity
ForEach(expenses) { expense in
    ExpenseRowView(
        amount: expense.amount,
        date: expense.date,
        notes: expense.notes,
        categoryName: expense.category.name
    )
}
```

**Rationale**: Passing models preserves identity, enables navigation, and maintains reactivity.

---

## Error Handling

### 1. Handle Errors Gracefully

**DO**: Catch errors and inform user

```swift
func addExpense() {
    let expense = Expense(...)
    modelContext.insert(expense)

    do {
        try modelContext.save()
        showSuccessAlert()
    } catch {
        showErrorAlert(message: error.localizedDescription)
    }
}
```

**DON'T**: Ignore errors silently

```swift
// ❌ User has no feedback
func addExpense() {
    let expense = Expense(...)
    modelContext.insert(expense)
    try? modelContext.save()  // Silent failure
}
```

**Exception**: Demo data and preview setup can use `try?` since failures are non-critical.

---

### 2. Validate Input Early

**DO**: Validate in model initializers

```swift
init(category: Category, monthlyLimit: Decimal, currentMonth: Date) throws {
    guard monthlyLimit > 0 else {
        throw BudgetError.invalidLimit("Budget must be positive, got \(monthlyLimit)")
    }
    self.monthlyLimit = monthlyLimit
    // ...
}
```

**DON'T**: Validate in views only

```swift
// ❌ Model can be created with invalid data
init(category: Category, monthlyLimit: Decimal, currentMonth: Date) {
    self.monthlyLimit = monthlyLimit  // Could be negative!
}

// View validation
func saveBudget() {
    guard monthlyLimit > 0 else {
        showError()
        return
    }
    // ...
}
```

**Rationale**: Model-level validation ensures data integrity regardless of entry point.

---

## Performance

### 1. Use Lazy Views

**DO**: Use `LazyVStack`/`LazyHStack` for large lists

```swift
ScrollView {
    LazyVStack {
        ForEach(expenses) { expense in
            ExpenseRowView(expense: expense)
        }
    }
}
```

**Note**: `List` is implicitly lazy, so no need for explicit `LazyVStack` inside `List`.

---

### 2. Avoid Expensive Computations in Body

**DO**: Cache expensive calculations

```swift
@State private var chartData: [MonthlyData] = []

var body: some View {
    Chart(chartData) { /* ... */ }
        .task {
            chartData = await calculateChartData()
        }
}
```

**DON'T**: Compute in body (computed on every render)

```swift
// ❌ Re-calculated on every render
var body: some View {
    Chart(calculateExpensiveChartData()) { /* ... */ }
}
```

**Rationale**: SwiftUI may call `body` multiple times per frame. Expensive calculations should be cached or memoized.

---

### 3. Scope Animations

**DO**: Animate specific values

```swift
.animation(.snappy, value: filteredExpenses.count)
```

**DON'T**: Use blanket animations

```swift
// ❌ Animates everything, including unintended changes
.animation(.snappy)
```

**Rationale**: Scoped animations are more predictable and performant.

---

## Testing

### 1. Test Business Logic, Not Views

**DO**: Test model logic and services

```swift
func testBudgetCalculation() throws {
    let category = Category(name: "Food", color: "orange", symbolName: "fork.knife")
    let budget = try Budget(category: category, monthlyLimit: 200, currentMonth: Date())

    let expense = Expense(amount: 50, date: Date(), category: category)
    category.expenses.append(expense)

    XCTAssertEqual(budget.calculateCurrentSpending(), 50)
}
```

**DON'T**: Test view rendering (use UI tests instead)

```swift
// ❌ Better suited for UI test
func testExpenseListViewRendersExpenses() {
    let view = ExpenseListView()
    // Can't easily test SwiftUI views in unit tests
}
```

**Rationale**: Business logic is easier to test and more important to verify than UI rendering.

---

### 2. Use Preview Data for Manual Testing

**DO**: Provide realistic preview data

```swift
#Preview {
    BudgetsView()
        .modelContainer(PreviewData.previewModelContainer)
}
```

**DON'T**: Use empty previews

```swift
// ❌ Can't see layout with data
#Preview {
    BudgetsView()
}
```

**Rationale**: Previews with data help visualize real-world scenarios during development.

---

### 3. Test Edge Cases

**DO**: Test boundary conditions

```swift
func testEndOfMonthCalculation() {
    let date = Date() // Mid-month
    let endOfMonth = date.endOfMonth

    let components = Calendar.current.dateComponents([.day], from: endOfMonth)
    XCTAssertEqual(components.day, 31) // or 30, 28, 29
}

func testBudgetWithZeroExpenses() throws {
    let budget = try Budget(category: category, monthlyLimit: 200, currentMonth: Date())
    XCTAssertEqual(budget.calculateCurrentSpending(), 0)
}
```

**Rationale**: Edge cases are where bugs hide. Test them explicitly.

---

## Accessibility

### 1. Provide VoiceOver Labels

**DO**: Add labels to all interactive elements

```swift
Button("Add") { addExpense() }
    .accessibilityLabel("Add new expense")

Image(systemName: "trash")
    .accessibilityLabel("Delete expense")
```

**DON'T**: Rely on visual-only cues

```swift
// ❌ VoiceOver reads "Button" (not helpful)
Button(action: addExpense) {
    Image(systemName: "plus")
}
```

---

### 2. Support Dynamic Type

**DO**: Use system font styles

```swift
Text("Expenses")
    .font(.headline)  // Automatically scales

Text("Total")
    .font(.title)     // Automatically scales
```

**DON'T**: Use fixed font sizes

```swift
// ❌ Does not scale with user preference
Text("Expenses")
    .font(.system(size: 18))
```

---

### 3. Use Color + Icon for Information

**DO**: Combine color with icons

```swift
HStack {
    Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.red)
    Text("Budget exceeded")
}
```

**DON'T**: Rely on color alone

```swift
// ❌ Color-blind users can't distinguish
Text("Budget exceeded")
    .foregroundStyle(.red)  // No icon
```

---

## Summary of Key Principles

### Architecture

1. Model-driven SwiftUI (no ViewModels)
2. Direct data access via `@Query`
3. Services for business logic
4. Feature-based organization

### State Management

1. `@Query` for SwiftData
2. `@State` for transient UI state
3. `@AppStorage` for persistent preferences
4. `@Bindable` for inline editing

### Code Quality

1. Extract complex logic
2. Name clearly and consistently
3. Test business logic
4. Handle errors gracefully

### Performance

1. Use lazy views for large lists
2. Cache expensive calculations
3. Scope animations
4. Avoid work in `body`

### User Experience

1. Support VoiceOver
2. Support Dynamic Type
3. Use color + icon
4. Provide haptic feedback

---

## Code Review Checklist

Before submitting a PR, verify:

- [ ] No ViewModels introduced
- [ ] `@Query` used for data fetching
- [ ] Errors handled with user feedback
- [ ] Complex views extracted to components
- [ ] Accessibility labels added to interactive elements
- [ ] Tests added for business logic
- [ ] Preview provided with sample data
- [ ] Naming follows conventions
- [ ] Documentation updated (if public API)
- [ ] Commit messages follow Conventional Commits

---

## Anti-Patterns to Avoid

### 1. Over-Engineering

```swift
// ❌ Too complex for simple task
protocol ExportService {
    var formatName: String { get }
    func export(_ expenses: [Expense]) -> Data?
}

class CSVExportServiceImpl: ExportService { /* ... */ }
class JSONExportServiceImpl: ExportService { /* ... */ }

class ExportServiceFactory {
    static func createService(for format: ExportFormat) -> ExportService { /* ... */ }
}

// ✅ Simple and clear
struct CSVService {
    static func exportExpenses(_ expenses: [Expense]) -> String { /* ... */ }
}
```

---

### 2. Premature Optimization

```swift
// ❌ Optimizing before profiling
@State private var cachedFilteredExpenses: [Expense] = []
@State private var lastFilterHash: Int = 0

var filteredExpenses: [Expense] {
    let hash = calculateFilterHash()
    if hash == lastFilterHash {
        return cachedFilteredExpenses
    }
    // Complex caching logic...
}

// ✅ Simple and fast enough
var filteredExpenses: [Expense] {
    expenses.filter { /* filter logic */ }
}
```

---

### 3. Magic Numbers

```swift
// ❌ What do these numbers mean?
let expenses = generateDemoExpenses(count: 87, daysBack: 183)

// ✅ Named constants
struct DemoDataConstants {
    static let expenseCount = 87
    static let daysBack = 183  // ~6 months
}

let expenses = generateDemoExpenses(
    count: DemoDataConstants.expenseCount,
    daysBack: DemoDataConstants.daysBack
)
```

---

## Conclusion

Following these best practices will help maintain code quality, readability, and performance in ExpenseTracker-SwiftUI. When in doubt, refer to existing code for examples and patterns.

**Remember**: Consistency is key. Follow established patterns even if you would do it differently in other projects.

---

**Last Updated**: 2025-01-23
**Version**: 1.0
