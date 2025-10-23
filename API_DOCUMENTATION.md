# API Documentation

## Overview

This document provides detailed API documentation for all public models, views, and services in ExpenseTracker-SwiftUI.

---

## Models

### Expense

**File**: `/ExpenseTracker/Models/Expense.swift`

**Description**: Represents a single expense transaction

```swift
@Model
final class Expense {
    var amount: Decimal
    var date: Date
    var notes: String?
    var isDemo: Bool

    @Relationship
    var category: Category

    init(
        amount: Decimal,
        date: Date,
        notes: String? = nil,
        category: Category,
        isDemo: Bool = false
    )
}
```

#### Properties

| Property | Type | Description | Required |
|----------|------|-------------|----------|
| `amount` | `Decimal` | Expense amount (positive value) | Yes |
| `date` | `Date` | Date when expense occurred | Yes |
| `notes` | `String?` | Optional notes/description | No |
| `isDemo` | `Bool` | Flag to identify demo/sample data | Yes (default: false) |
| `category` | `Category` | Associated category | Yes |

#### Relationships

- **Many-to-One with Category**: Each expense belongs to exactly one category
- **Cascade Delete**: Deleting the category deletes all associated expenses

#### Usage Example

```swift
let category = Category(name: "Food", color: "orange", symbolName: "fork.knife")
let expense = Expense(
    amount: 42.50,
    date: Date(),
    notes: "Lunch at cafe",
    category: category
)
modelContext.insert(expense)
try modelContext.save()
```

#### Validation

- `amount`: Must be positive (enforced by business logic, not model)
- `category`: Must be non-nil (enforced by SwiftData)

---

### Category

**File**: `/ExpenseTracker/Models/Category.swift`

**Description**: Represents an expense category for organization and reporting

```swift
@Model
final class Category {
    var name: String
    var color: String
    var symbolName: String

    @Relationship(deleteRule: .cascade, inverse: \Expense.category)
    var expenses: [Expense] = []

    init(
        name: String,
        color: String,
        symbolName: String
    )
}
```

#### Properties

| Property | Type | Description | Required |
|----------|------|-------------|----------|
| `name` | `String` | Category name (e.g., "Food", "Transportation") | Yes |
| `color` | `String` | Color name (e.g., "orange", "blue") | Yes |
| `symbolName` | `String` | SF Symbol name (e.g., "fork.knife") | Yes |
| `expenses` | `[Expense]` | Associated expenses (managed by SwiftData) | No |

#### Relationships

- **One-to-Many with Expense**: A category can have multiple expenses
- **Cascade Delete**: Deleting a category deletes all associated expenses
- **Inverse Relationship**: Maintains bidirectional sync with Expense

#### Supported Colors

```
orange, blue, purple, pink, red, gray, green, yellow, indigo, brown, teal
```

#### Usage Example

```swift
let category = Category(
    name: "Food",
    color: "orange",
    symbolName: "fork.knife"
)
modelContext.insert(category)
try modelContext.save()
```

#### Special Categories

- **"Uncategorized"**: Protected category created automatically when needed
  - Cannot be deleted by user
  - Used as fallback when deleting other categories

---

### Budget

**File**: `/ExpenseTracker/Models/Budget.swift`

**Description**: Tracks monthly spending limits per category

```swift
@Model
final class Budget {
    @Attribute(.unique) var id: UUID

    @Relationship
    var category: Category

    var monthlyLimit: Decimal
    var currentMonth: Date
    var notes: String?
    var isDemo: Bool

    init(
        id: UUID = UUID(),
        category: Category,
        monthlyLimit: Decimal,
        currentMonth: Date,
        notes: String? = nil,
        isDemo: Bool = false
    ) throws
}
```

#### Properties

| Property | Type | Description | Required |
|----------|------|-------------|----------|
| `id` | `UUID` | Unique identifier | Yes (auto-generated) |
| `category` | `Category` | Associated category | Yes |
| `monthlyLimit` | `Decimal` | Budget limit for the month | Yes |
| `currentMonth` | `Date` | Month this budget applies to (normalized to first day) | Yes |
| `notes` | `String?` | Optional notes | No |
| `isDemo` | `Bool` | Flag for demo data | Yes (default: false) |

#### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `percentageUsed` | `Double` | Percentage of budget spent (0-100+) |
| `amountRemaining` | `Decimal` | Amount remaining in budget (minimum 0) |
| `isAlertThreshold` | `Bool` | True if spending >= 75% of limit |
| `isWarningThreshold` | `Bool` | True if spending >= 90% of limit |

#### Methods

##### calculateCurrentSpending()

```swift
func calculateCurrentSpending() -> Decimal
```

**Description**: Calculate total spending for this budget's category in current month

**Returns**: Total spending amount (excludes demo expenses)

**Algorithm**:
1. Get month start and end dates
2. Filter category expenses within date range
3. Exclude demo expenses (`isDemo == true`)
4. Sum filtered expense amounts

**Example**:
```swift
let budget = try Budget(
    category: foodCategory,
    monthlyLimit: 200,
    currentMonth: Date()
)
let spent = budget.calculateCurrentSpending()  // e.g., 150.00
```

#### Validation

- `monthlyLimit`: Must be positive (throws `BudgetError.invalidLimit` if not)

#### Errors

```swift
enum BudgetError: Error {
    case invalidLimit(String)
}
```

**Thrown when**: `monthlyLimit <= 0`

#### Usage Example

```swift
do {
    let budget = try Budget(
        category: foodCategory,
        monthlyLimit: 200,
        currentMonth: Date(),
        notes: "Monthly food budget"
    )
    modelContext.insert(budget)
    try modelContext.save()
} catch BudgetError.invalidLimit(let message) {
    print("Invalid budget: \(message)")
}
```

---

## Views

### ExpenseListView

**File**: `/ExpenseTracker/Features/Expenses/ExpenseListView.swift`

**Description**: Main view for displaying and managing expenses

```swift
struct ExpenseListView: View {
    var body: some View
}
```

#### State Properties

| Property | Type | Description |
|----------|------|-------------|
| `expenses` | `[Expense]` | All expenses (from `@Query`) |
| `categories` | `[Category]` | All categories (from `@Query`) |
| `searchText` | `String` | Search filter text |
| `filterTypeRaw` | `String` | Date range filter (persisted via `@AppStorage`) |
| `selectedCategoryName` | `String?` | Selected category filter (persisted via `@AppStorage`) |

#### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `filteredExpenses` | `[Expense]` | Expenses after applying filters |
| `navigationTitle` | `String` | Dynamic title showing active filter |
| `hasActiveFilters` | `Bool` | True if any filters are active |

#### Features

1. **Filtering**:
   - Date ranges: All Time, This Month, Last Month, Last 7/30 Days, Year to Date, Custom
   - Category selection
   - Text search (notes and category name)

2. **Actions**:
   - Add new expense
   - Edit existing expense (tap row)
   - Delete expense (swipe)
   - Export (CSV, JSON, PDF, Excel)

3. **Empty States**:
   - No expenses: "Add your first expense"
   - No results from filters: "Clear Filters" button
   - No search results: System search empty state

#### Usage

```swift
TabView {
    ExpenseListView()
        .tabItem {
            Image(systemName: "list.bullet")
            Text("Expenses")
        }
}
```

---

### DashboardView

**File**: `/ExpenseTracker/Features/Dashboard/DashboardView.swift`

**Description**: Visualizes spending trends and category breakdown

```swift
struct DashboardView: View {
    var body: some View
}
```

#### State Properties

| Property | Type | Description |
|----------|------|-------------|
| `expenses` | `[Expense]` | All expenses (from `@Query`) |
| `categories` | `[Category]` | All categories (from `@Query`) |
| `timeRangeRaw` | `String` | Chart time range (6M/12M, persisted via `@AppStorage`) |

#### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `filteredExpenses` | `[Expense]` | Expenses after applying date/category filters |
| `monthlyData` | `[MonthlyData]` | Aggregated spending per month |
| `categoryData` | `[CategoryData]` | Spending breakdown by category |
| `totalAmount` | `Decimal` | Total spending in filtered period |
| `monthlyTrendData` | `(amount: Decimal, percentage: Double)?` | Month-over-month comparison |
| `topCategory` | `CategoryData?` | Highest spending category |

#### Components

1. **Summary Cards**:
   - Total spending
   - Monthly trend (comparison with previous period)
   - Top category

2. **Charts**:
   - Monthly trend bar chart (6 or 12 months)
   - Category breakdown donut chart with legend

3. **Budget Overview**:
   - `BudgetProgressCard` component

#### Usage

```swift
TabView {
    DashboardView()
        .tabItem {
            Image(systemName: "chart.pie")
            Text("Dashboard")
        }
}
```

---

### BudgetsView

**File**: `/ExpenseTracker/Features/Budgets/BudgetsView.swift`

**Description**: Manages monthly spending budgets per category

```swift
struct BudgetsView: View {
    var body: some View
}
```

#### State Properties

| Property | Type | Description |
|----------|------|-------------|
| `budgets` | `[Budget]` | All budgets (from `@Query`) |
| `showingAddSheet` | `Bool` | Controls add budget sheet |
| `selectedBudget` | `Budget?` | Budget being edited |

#### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `currentMonthBudgets` | `[Budget]` | Budgets for current month only |

#### Features

1. **Display**: List of budgets with progress bars
2. **Color Coding**:
   - Green: < 75% spent
   - Yellow: 75-90% spent
   - Red: > 90% spent
3. **Actions**:
   - Add new budget
   - Edit budget (tap row)
   - Delete budget (swipe)

#### Usage

```swift
TabView {
    BudgetsView()
        .tabItem {
            Image(systemName: "dollarsign.circle.fill")
            Text("Budgets")
        }
}
```

---

### CategoriesView

**File**: `/ExpenseTracker/Features/Categories/CategoriesView.swift`

**Description**: Manages expense categories

```swift
struct CategoriesView: View {
    var body: some View
}
```

#### State Properties

| Property | Type | Description |
|----------|------|-------------|
| `categories` | `[Category]` | All categories (from `@Query`) |
| `showingAddSheet` | `Bool` | Controls add category sheet |
| `categoryToEdit` | `Category?` | Category being edited |

#### Features

1. **Display**: List of categories with color swatch and icon
2. **Protection**: "Uncategorized" category cannot be deleted
3. **Safe Delete**: Reassigns expenses to "Uncategorized" before deletion
4. **Actions**:
   - Add new category
   - Edit category (tap row)
   - Delete category (swipe, with protection)

#### Usage

```swift
TabView {
    CategoriesView()
        .tabItem {
            Image(systemName: "tag")
            Text("Categories")
        }
}
```

---

### SettingsView

**File**: `/ExpenseTracker/Features/Settings/SettingsView.swift`

**Description**: App configuration and data management

```swift
struct SettingsView: View {
    var body: some View
}
```

#### State Properties

| Property | Type | Description |
|----------|------|-------------|
| `expenses` | `[Expense]` | All expenses (from `@Query`) |
| `demoModeEnabled` | `Bool` | Demo mode toggle (persisted via `@AppStorage`) |
| `exportFileURL` | `URL?` | Exported file for sharing |

#### Sections

1. **Demo Data**:
   - Toggle demo mode
   - Generate sample expenses
   - Remove demo data

2. **Data Management**:
   - Import CSV
   - Export (CSV, JSON, PDF, Excel)
   - Share exported file

3. **App Info**:
   - App name and description
   - Version and build number

#### Usage

```swift
TabView {
    SettingsView()
        .tabItem {
            Image(systemName: "gear")
            Text("Settings")
        }
}
```

---

## Services

### CSVService

**File**: `/ExpenseTracker/Features/Settings/CSVService.swift`

**Description**: Handles CSV import and export operations

#### Methods

##### exportExpenses(_:)

```swift
static func exportExpenses(_ expenses: [Expense]) -> String
```

**Parameters**:
- `expenses`: Array of expenses to export

**Returns**: CSV-formatted string

**Format**:
```
date,amount,category,notes
2025-01-15,42.50,Food,"Lunch at cafe"
2025-01-16,120.00,Transportation,"Gas"
```

**Example**:
```swift
let csvContent = CSVService.exportExpenses(expenses)
```

---

##### createTempCSVFile(content:)

```swift
static func createTempCSVFile(content: String) -> URL?
```

**Parameters**:
- `content`: CSV string to write

**Returns**: URL to temporary file, or nil if failed

**File naming**: `expenses-YYYY-MM-DD_HH-mm.csv`

**Example**:
```swift
if let fileURL = CSVService.createTempCSVFile(content: csvContent) {
    // Share fileURL
}
```

---

##### importCSV(from:into:existingExpenses:existingCategories:)

```swift
static func importCSV(
    from url: URL,
    into modelContext: ModelContext,
    existingExpenses: [Expense],
    existingCategories: [Category]
) -> ImportResult
```

**Parameters**:
- `url`: URL to CSV file
- `modelContext`: SwiftData context for inserting
- `existingExpenses`: Current expenses (for duplicate detection)
- `existingCategories`: Current categories (for category lookup/creation)

**Returns**: `ImportResult` struct with statistics

**ImportResult**:
```swift
struct ImportResult {
    let imported: Int           // Successfully imported
    let duplicatesSkipped: Int  // Skipped duplicates
    let invalidRows: Int        // Invalid/malformed rows
    let errors: [String]        // Error messages
}
```

**Duplicate Detection**: Considers date, amount, notes, and category name

**Example**:
```swift
let result = CSVService.importCSV(
    from: fileURL,
    into: modelContext,
    existingExpenses: expenses,
    existingCategories: categories
)
print("Imported: \(result.imported), Skipped: \(result.duplicatesSkipped)")
```

---

##### exportExpensesAsJSON(_:)

```swift
static func exportExpensesAsJSON(_ expenses: [Expense]) -> String
```

**Parameters**:
- `expenses`: Array of expenses to export

**Returns**: JSON-formatted string

**Format**:
```json
[
  {
    "amount": "42.50",
    "category": "Food",
    "date": "2025-01-15",
    "notes": "Lunch at cafe"
  }
]
```

---

##### createTempJSONFile(content:)

```swift
static func createTempJSONFile(content: String) -> URL?
```

**Parameters**:
- `content`: JSON string to write

**Returns**: URL to temporary file, or nil if failed

**File naming**: `expenses-YYYY-MM-DD_HH-mm.json`

---

### PDFExportService

**File**: `/ExpenseTracker/Features/Settings/PDFExportService.swift`

**Description**: Handles PDF export operations

#### Methods

##### exportExpensesAsPDF(_:)

```swift
static func exportExpensesAsPDF(_ expenses: [Expense]) -> Data?
```

**Parameters**:
- `expenses`: Array of expenses to export

**Returns**: PDF data, or nil if generation failed

**Example**:
```swift
if let pdfData = PDFExportService.exportExpensesAsPDF(expenses) {
    // Save or share PDF
}
```

---

##### createTempPDFFile(data:)

```swift
static func createTempPDFFile(data: Data) -> URL?
```

**Parameters**:
- `data`: PDF data to write

**Returns**: URL to temporary file, or nil if failed

**File naming**: `expenses-YYYY-MM-DD_HH-mm.pdf`

---

### ExcelExportService

**File**: `/ExpenseTracker/Features/Settings/ExcelExportService.swift`

**Description**: Handles Excel (.xlsx) export operations

#### Methods

##### exportExpensesAsExcel(_:)

```swift
static func exportExpensesAsExcel(_ expenses: [Expense]) -> Data?
```

**Parameters**:
- `expenses`: Array of expenses to export

**Returns**: Excel file data, or nil if generation failed

---

##### createTempExcelFile(data:)

```swift
static func createTempExcelFile(data: Data) -> URL?
```

**Parameters**:
- `data`: Excel data to write

**Returns**: URL to temporary file, or nil if failed

**File naming**: `expenses-YYYY-MM-DD_HH-mm.xlsx`

---

### DemoDataService

**File**: `/ExpenseTracker/Features/Settings/DemoDataService.swift`

**Description**: Manages demo/sample data generation and removal

#### Methods

##### insertDemoData(modelContext:categories:)

```swift
static func insertDemoData(
    modelContext: ModelContext,
    categories: [Category]
) -> Int
```

**Parameters**:
- `modelContext`: SwiftData context for inserting
- `categories`: Available categories to use

**Returns**: Number of demo expenses created

**Generation Rules**:
- Creates 50-100 random expenses
- Spans 6-12 months in the past
- Random amounts between $5-$200
- Distributed across provided categories
- All marked with `isDemo = true`

**Example**:
```swift
let count = DemoDataService.insertDemoData(
    modelContext: modelContext,
    categories: categories
)
print("Generated \(count) demo expenses")
```

---

##### removeDemoData(modelContext:)

```swift
static func removeDemoData(modelContext: ModelContext) -> Int
```

**Parameters**:
- `modelContext`: SwiftData context

**Returns**: Number of demo expenses removed

**Example**:
```swift
let removed = DemoDataService.removeDemoData(modelContext: modelContext)
print("Removed \(removed) demo expenses")
```

---

## Enums

### DateRangeFilter

**File**: `/ExpenseTracker/Features/Expenses/DateRangeFilter.swift`

**Description**: Defines date range filtering options

```swift
enum DateRangeFilter: String, CaseIterable {
    case allTime
    case thisMonth
    case lastMonth
    case last7Days
    case last30Days
    case yearToDate
    case custom
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `displayName` | `String` | User-facing display name |
| `shortDisplayName` | `String` | Abbreviated display name |

#### Methods

##### dateRange(customStart:customEnd:)

```swift
func dateRange(
    customStart: Date? = nil,
    customEnd: Date? = nil
) -> (start: Date, end: Date)?
```

**Parameters**:
- `customStart`: Start date for `.custom` filter
- `customEnd`: End date for `.custom` filter

**Returns**: Tuple with start and end dates, or nil for `.allTime`

**Example**:
```swift
let filter = DateRangeFilter.thisMonth
if let range = filter.dateRange() {
    let expenses = allExpenses.filter {
        $0.date >= range.start && $0.date <= range.end
    }
}
```

---

### BudgetError

**File**: `/ExpenseTracker/Models/Budget.swift`

**Description**: Error types for budget operations

```swift
enum BudgetError: Error {
    case invalidLimit(String)
}
```

**Cases**:
- `invalidLimit(String)`: Thrown when budget limit is not positive

---

## Extensions

### Date

**File**: `/ExpenseTracker/Models/Budget.swift`

**Description**: Date calculation helpers

#### Properties

##### startOfMonth

```swift
var startOfMonth: Date
```

**Returns**: First day of the month at midnight

**Example**:
```swift
let date = Date()
let monthStart = date.startOfMonth
// e.g., 2025-01-01 00:00:00
```

---

##### endOfMonth

```swift
var endOfMonth: Date
```

**Returns**: Last day of the month at 23:59:59

**Example**:
```swift
let date = Date()
let monthEnd = date.endOfMonth
// e.g., 2025-01-31 23:59:59
```

---

## Preview Data

### PreviewData

**File**: `/ExpenseTracker/Models/PreviewData.swift`

**Description**: Provides sample data for SwiftUI previews

```swift
struct PreviewData {
    static let previewModelContainer: ModelContainer
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `previewModelContainer` | `ModelContainer` | In-memory container with sample data |

#### Usage

```swift
#Preview {
    ExpenseListView()
        .modelContainer(PreviewData.previewModelContainer)
}
```

#### Sample Data

- 4 categories (Food, Transportation, Entertainment, Shopping)
- 10 expenses across current month
- 4 budgets with varying spending levels (45%-130%)

---

## Helper Functions

### colorForCategory(_:)

**File**: `/ExpenseTracker/Features/Dashboard/DashboardComponents.swift`

**Description**: Maps color name to SwiftUI Color

```swift
func colorForCategory(_ colorName: String) -> Color
```

**Parameters**:
- `colorName`: Color name string (e.g., "orange", "blue")

**Returns**: Corresponding SwiftUI Color (defaults to .blue)

**Supported Colors**:
```
orange, blue, purple, pink, red, gray, green, yellow, indigo, brown, teal
```

**Example**:
```swift
let color = colorForCategory("orange")  // Color.orange
```

---

## App Configuration

### ExpenseTrackerApp

**File**: `/ExpenseTracker/ExpenseTrackerApp.swift`

**Description**: App entry point and SwiftData setup

```swift
@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { seedDefaultCategoriesIfNeeded() }
        }
        .modelContainer(for: [Expense.self, Category.self, Budget.self])
    }
}
```

#### Methods

##### seedDefaultCategoriesIfNeeded()

**Description**: Seeds default categories on first launch

**Default Categories**:
1. Food (orange, fork.knife)
2. Transportation (blue, car.fill)
3. Entertainment (purple, tv.fill)
4. Shopping (pink, bag.fill)
5. Bills (red, doc.text.fill)
6. Other (gray, ellipsis.circle.fill)

**Behavior**: Only seeds if no categories exist

---

## Type Definitions

### MonthlyData

**File**: `/ExpenseTracker/Features/Dashboard/DashboardView.swift`

**Description**: Aggregated spending data for chart display

```swift
struct MonthlyData {
    let month: Date
    let amount: Decimal
    let monthName: String
}
```

---

### CategoryData

**File**: `/ExpenseTracker/Features/Dashboard/DashboardView.swift`

**Description**: Category spending breakdown for pie chart

```swift
struct CategoryData {
    let category: Category
    let amount: Decimal
    let percentage: Double
}
```

---

### DashboardTimeRange

**File**: `/ExpenseTracker/Features/Dashboard/DashboardView.swift`

**Description**: Time range options for dashboard charts

```swift
enum DashboardTimeRange: String, CaseIterable {
    case sixMonths = "6M"
    case twelveMonths = "12M"

    var monthsBack: Int
}
```

---

## Usage Patterns

### Creating an Expense

```swift
// 1. Get model context
@Environment(\.modelContext) private var modelContext

// 2. Create expense
let expense = Expense(
    amount: 42.50,
    date: Date(),
    notes: "Lunch",
    category: selectedCategory
)

// 3. Insert and save
modelContext.insert(expense)
do {
    try modelContext.save()
} catch {
    print("Failed to save: \(error)")
}
```

---

### Querying Expenses

```swift
// Basic query
@Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

// Filtered query
let descriptor = FetchDescriptor<Expense>(
    predicate: #Predicate { expense in
        expense.category.name == "Food"
    }
)
let foodExpenses = try modelContext.fetch(descriptor)
```

---

### Filtering Expenses

```swift
// Date range filter
let filter = DateRangeFilter.thisMonth
if let range = filter.dateRange() {
    let filtered = expenses.filter {
        $0.date >= range.start && $0.date <= range.end
    }
}

// Category filter
let filtered = expenses.filter { $0.category.name == "Food" }

// Search filter
let filtered = expenses.filter {
    $0.notes?.localizedCaseInsensitiveContains(searchText) ?? false
}
```

---

### Exporting Data

```swift
// CSV
let csvContent = CSVService.exportExpenses(expenses)
if let fileURL = CSVService.createTempCSVFile(content: csvContent) {
    // Share fileURL
}

// JSON
let jsonContent = CSVService.exportExpensesAsJSON(expenses)
if let fileURL = CSVService.createTempJSONFile(content: jsonContent) {
    // Share fileURL
}

// PDF
if let pdfData = PDFExportService.exportExpensesAsPDF(expenses) {
    if let fileURL = PDFExportService.createTempPDFFile(data: pdfData) {
        // Share fileURL
    }
}
```

---

### Importing Data

```swift
let result = CSVService.importCSV(
    from: fileURL,
    into: modelContext,
    existingExpenses: expenses,
    existingCategories: categories
)

print("Imported: \(result.imported)")
print("Duplicates: \(result.duplicatesSkipped)")
print("Errors: \(result.errors.joined(separator: ", "))")
```

---

## Error Handling

### Model Validation

```swift
do {
    let budget = try Budget(
        category: category,
        monthlyLimit: -100,  // Invalid!
        currentMonth: Date()
    )
} catch BudgetError.invalidLimit(let message) {
    print("Error: \(message)")
}
```

---

### File Operations

```swift
if let fileURL = CSVService.createTempCSVFile(content: csvContent) {
    // Success
} else {
    // Handle failure (file URL is nil)
    print("Failed to create CSV file")
}
```

---

### SwiftData Operations

```swift
do {
    try modelContext.save()
} catch {
    print("Save failed: \(error)")
    // Show alert to user
}
```

---

## Accessibility

### VoiceOver Labels

```swift
// Button
Button("Add") { }
    .accessibilityLabel("Add new expense")

// Row
ExpenseRowView(expense: expense)
    .accessibilityLabel("\(expense.category.name) expense")
    .accessibilityValue("\(expense.amount, format: .currency(code: "USD"))")
    .accessibilityAddTraits(.isButton)
```

---

### Dynamic Type Support

All text automatically scales with user's font size preference:

```swift
Text("Expenses")
    .font(.body)  // Scales automatically

Text("Total")
    .font(.title)  // Scales automatically
```

---

## Threading & Concurrency

### Main Actor

All UI updates are on the main actor (SwiftUI default):

```swift
@MainActor
struct ExpenseListView: View {
    // All body evaluations on main thread
}
```

---

### Background Context

For heavy operations (not currently used):

```swift
let backgroundContext = ModelContext(modelContainer)
await backgroundContext.perform {
    // Heavy operation
    try backgroundContext.save()
}
```

---

## Best Practices

### 1. Always use ModelContext for mutations

```swift
// ✅ Good
modelContext.insert(expense)
try modelContext.save()

// ❌ Bad
expenses.append(expense)  // Does not persist
```

---

### 2. Use @Query for reactive data

```swift
// ✅ Good
@Query private var expenses: [Expense]

// ❌ Bad
let expenses = try modelContext.fetch(FetchDescriptor<Expense>())
```

---

### 3. Filter in memory for UI-level filters

```swift
// ✅ Good for UI filters
private var filteredExpenses: [Expense] {
    expenses.filter { /* logic */ }
}

// ❌ Over-engineering for simple filters
let descriptor = FetchDescriptor<Expense>(predicate: ...)
```

---

### 4. Use PreviewData for previews

```swift
// ✅ Good
#Preview {
    ExpenseListView()
        .modelContainer(PreviewData.previewModelContainer)
}

// ❌ Bad
#Preview {
    ExpenseListView()
    // No data, view will be empty
}
```

---

## Summary

This API documentation covers all public interfaces in ExpenseTracker-SwiftUI. For implementation details, refer to individual source files. For architectural patterns, see ARCHITECTURE.md.
