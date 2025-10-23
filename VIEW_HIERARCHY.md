# View Hierarchy Documentation

## Overview

ExpenseTracker-SwiftUI uses a **tab-based navigation** structure with five main feature areas. Each tab contains a self-contained feature with its own views, sheets, and components.

---

## App Entry Point

### ExpenseTrackerApp

**File**: `/ExpenseTracker/ExpenseTrackerApp.swift`

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

**Responsibilities**:
- Sets up SwiftData container
- Seeds default categories on first launch
- Provides root view (`ContentView`)

---

## Root View

### ContentView

**File**: `/ExpenseTracker/ContentView.swift`

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            ExpenseListView()      // Tab 1: Expenses
            DashboardView()        // Tab 2: Dashboard
            BudgetsView()          // Tab 3: Budgets
            CategoriesView()       // Tab 4: Categories
            SettingsView()         // Tab 5: Settings
        }
    }
}
```

**Navigation Structure**:
```
TabView (root)
├── Tab 1: Expenses (list.bullet)
├── Tab 2: Dashboard (chart.pie)
├── Tab 3: Budgets (dollarsign.circle.fill)
├── Tab 4: Categories (tag)
└── Tab 5: Settings (gear)
```

---

## Feature 1: Expenses

### ExpenseListView (Main View)

**File**: `/ExpenseTracker/Features/Expenses/ExpenseListView.swift`

**Purpose**: Display and manage expense list with filtering

**State Management**:
```swift
// SwiftData queries
@Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
@Query private var categories: [Category]

// UI state
@State private var searchText = ""
@State private var showingAddSheet = false
@State private var expenseToEdit: Expense?

// Persistent filters
@AppStorage("filterType") private var filterTypeRaw = DateRangeFilter.defaultFilter.rawValue
@AppStorage("selectedCategoryName") private var selectedCategoryName: String?
```

**View Hierarchy**:
```
NavigationStack
└── Group (conditional content)
    ├── ContentUnavailableView (no expenses)
    ├── filterEmptyStateView (no results from filters)
    └── VStack
        ├── Filter indicator banner (if filters active)
        └── List
            └── ForEach(filteredExpenses)
                └── ExpenseRowView
```

**Modifiers**:
- `.navigationTitle()`: Dynamic title based on filter
- `.searchable()`: Search by notes/category
- `.navigationBarItems()`: Filter menu + export + add buttons
- `.sheet()`: AddExpenseSheet, EditExpenseSheet, CustomDateRangeSheet

**Key Features**:
1. **Date Range Filters**: All Time, This Month, Last Month, Last 7/30 Days, Year to Date, Custom
2. **Category Filters**: Filter by single category
3. **Search**: Filter by notes or category name
4. **Export**: CSV, JSON, PDF, Excel
5. **Inline Editing**: Tap expense to edit

### ExpenseRowView (Component)

**File**: `/ExpenseTracker/Features/Expenses/ExpenseRowView.swift`

**Purpose**: Single expense row display

**Layout**:
```
HStack
├── VStack (leading)
│   ├── Text(category.name) + Icon
│   └── Text(notes) [optional]
├── Spacer
└── VStack (trailing)
    ├── Text(amount)
    └── Text(date)
```

### AddExpenseSheet (Sheet)

**File**: `/ExpenseTracker/Features/Expenses/AddExpenseSheet.swift`

**Purpose**: Create or edit expense

**Form Fields**:
- Amount (TextField with NumberFormatter)
- Category (Picker)
- Date (DatePicker)
- Notes (TextField, optional)

**Usage**:
```swift
AddExpenseSheet()                    // Create new
AddExpenseSheet(expense: existing)   // Edit existing
```

### CustomDateRangeSheet (Sheet)

**File**: `/ExpenseTracker/Features/Expenses/CustomDateRangeSheet.swift`

**Purpose**: Select custom date range for filters

**Form Fields**:
- Start Date (DatePicker)
- End Date (DatePicker)
- Apply Button

### DateRangeFilter (Enum)

**File**: `/ExpenseTracker/Features/Expenses/DateRangeFilter.swift`

**Purpose**: Define date range filter options

```swift
enum DateRangeFilter: String, CaseIterable {
    case allTime, thisMonth, lastMonth, last7Days, last30Days, yearToDate, custom

    func dateRange(customStart: Date?, customEnd: Date?) -> (start: Date, end: Date)?
}
```

---

## Feature 2: Dashboard

### DashboardView (Main View)

**File**: `/ExpenseTracker/Features/Dashboard/DashboardView.swift`

**Purpose**: Visualize spending trends and category breakdown

**State Management**:
```swift
@Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
@Query private var categories: [Category]

// Reads same filters as ExpenseListView
@AppStorage("filterType") private var filterTypeRaw = ...
@AppStorage("dashboardTimeRange") private var timeRangeRaw = ...
```

**View Hierarchy**:
```
NavigationStack
└── Conditional (hasData)
    ├── ScrollView
    │   └── VStack
    │       ├── Summary Cards (VStack)
    │       │   ├── SummaryCardView (Total)
    │       │   ├── TrendCardView (monthly comparison)
    │       │   └── TopCategoryCardView
    │       ├── Trends Section (VStack)
    │       │   ├── Header + Picker (6M / 12M)
    │       │   └── MonthlyTrendChartView
    │       ├── Category Breakdown Section
    │       │   └── CategoryBreakdownChartView
    │       └── BudgetProgressCard
    └── DashboardEmptyStateView
```

**Key Features**:
1. **Summary Cards**: Total spending, monthly trend, top category
2. **Monthly Trend Chart**: Bar chart of last 6/12 months
3. **Category Breakdown**: Donut chart with legend
4. **Budget Overview**: Card showing all budgets
5. **Filter Sync**: Respects filters from ExpenseListView

### DashboardComponents (Components)

**File**: `/ExpenseTracker/Features/Dashboard/DashboardComponents.swift`

**Components**:

1. **SummaryCardView**: Displays single metric with icon
2. **TrendCardView**: Shows month-over-month change with percentage
3. **TopCategoryCardView**: Highlights highest spending category
4. **MonthlyTrendChartView**: Bar chart using Swift Charts
5. **CategoryBreakdownChartView**: Donut chart with legend
6. **DashboardEmptyStateView**: No data placeholder

**Chart Usage**:
```swift
Chart(monthlyData, id: \.month) { data in
    BarMark(
        x: .value("Month", data.monthName),
        y: .value("Amount", Double(truncating: data.amount as NSDecimalNumber))
    )
}
```

---

## Feature 3: Budgets

### BudgetsView (Main View)

**File**: `/ExpenseTracker/Features/Budgets/BudgetsView.swift`

**Purpose**: Manage monthly spending budgets per category

**State Management**:
```swift
@Query private var budgets: [Budget]
@Environment(\.modelContext) private var modelContext

@State private var showingAddSheet = false
@State private var selectedBudget: Budget?
```

**View Hierarchy**:
```
NavigationStack
└── Conditional (currentMonthBudgets.isEmpty)
    ├── Empty State (VStack)
    │   ├── ContentUnavailableView
    │   └── Button (Add Budget)
    └── List
        └── ForEach(currentMonthBudgets)
            └── BudgetRowView
```

**Key Features**:
1. **Monthly Filtering**: Shows only current month budgets
2. **Progress Visualization**: Color-coded progress bars
3. **Threshold Alerts**: Visual warnings at 75% (yellow) and 90% (red)
4. **Tap to Edit**: Inline editing via sheet

### BudgetRowView (Component)

**File**: Inline in `BudgetsView.swift`

**Layout**:
```
VStack
├── Header (HStack)
│   ├── Icon + Category Name
│   └── Percentage
├── Progress Bar (VStack)
│   ├── GeometryReader (bar visualization)
│   └── Amount Details (HStack)
│       ├── Spent
│       ├── Limit
│       └── Remaining
└── Notes (optional)
```

**Color Logic**:
- Green: < 75% spent
- Yellow: 75-90% spent
- Red: > 90% spent

### AddBudgetSheet / EditBudgetSheet (Sheets)

**Files**:
- `/ExpenseTracker/Features/Budgets/AddBudgetSheet.swift`
- `/ExpenseTracker/Features/Budgets/EditBudgetSheet.swift`

**Form Fields**:
- Category (Picker)
- Monthly Limit (TextField with currency formatter)
- Notes (TextField, optional)

### BudgetProgressCard (Component)

**File**: `/ExpenseTracker/Features/Budgets/BudgetProgressCard.swift`

**Purpose**: Summary card shown on Dashboard

**Layout**: Mini version of BudgetRowView showing all budgets

---

## Feature 4: Categories

### CategoriesView (Main View)

**File**: `/ExpenseTracker/Features/Categories/CategoriesView.swift`

**Purpose**: Manage expense categories

**State Management**:
```swift
@Query(sort: \Category.name) private var categories: [Category]
@Environment(\.modelContext) private var modelContext

@State private var showingAddSheet = false
@State private var categoryToEdit: Category?
```

**View Hierarchy**:
```
NavigationStack
└── Group (conditional)
    ├── ContentUnavailableView (no categories)
    └── List
        └── ForEach(categories)
            └── CategoryRowView
```

**Key Features**:
1. **Protected "Uncategorized"**: Cannot delete, auto-created
2. **Safe Delete**: Reassigns expenses to "Uncategorized" before deleting category
3. **Color + Icon**: Visual customization via SF Symbols

**Delete Logic**:
```swift
private func confirmDelete() {
    // 1. Ensure "Uncategorized" exists
    // 2. Fetch all expenses for deleted category
    // 3. Reassign expenses to "Uncategorized"
    // 4. Delete category
    // 5. Save context
}
```

### CategoryRowView (Component)

**File**: Inline in `CategoriesView.swift`

**Layout**:
```
HStack
├── Circle (color swatch)
├── Image (SF Symbol)
├── Text (category name)
├── Spacer
└── Lock Icon (if uncategorized)
```

### AddCategorySheet (Sheet)

**File**: `/ExpenseTracker/Features/Categories/AddCategorySheet.swift`

**Form Fields**:
- Name (TextField)
- Color (ColorPalette picker)
- Symbol (SFSymbolPicker)

**Usage**:
```swift
AddCategorySheet()                   // Create new
AddCategorySheet(category: existing) // Edit existing
```

### ColorPalette (Component)

**File**: `/ExpenseTracker/Features/Categories/ColorPalette.swift`

**Purpose**: Color selection grid

**Colors**: green, blue, orange, pink, red, purple, teal, yellow, indigo, brown, gray

### SFSymbolPicker (Component)

**File**: `/ExpenseTracker/Features/Categories/SFSymbolPicker.swift`

**Purpose**: SF Symbol selection grid

**Common Symbols**: fork.knife, car.fill, house.fill, bag.fill, etc.

---

## Feature 5: Settings

### SettingsView (Main View)

**File**: `/ExpenseTracker/Features/Settings/SettingsView.swift`

**Purpose**: App configuration and data management

**State Management**:
```swift
@Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
@AppStorage("demoModeEnabled") private var demoModeEnabled = false

@State private var exportFileURL: URL?
@State private var showingImportPicker = false
```

**View Hierarchy**:
```
NavigationStack
└── Form
    ├── SettingsDemoSection
    │   ├── Toggle (Demo Mode)
    │   ├── Button (Generate Demo Data)
    │   └── Button (Remove Demo Data)
    ├── SettingsDataSection
    │   ├── Button (Import CSV)
    │   ├── Menu (Export)
    │   │   ├── CSV
    │   │   ├── JSON
    │   │   ├── PDF
    │   │   └── Excel
    │   └── ShareLink (if exported)
    └── App Info Section
        ├── App Name + Description
        └── Version + Build Number
```

**Key Features**:
1. **Demo Data**: Generate/remove sample expenses for testing
2. **Import**: CSV file import with duplicate detection
3. **Export**: Multiple formats (CSV, JSON, PDF, Excel)
4. **Filter Sync**: Exports use current filters from ExpenseListView

### SettingsDemoSection / SettingsDataSection (Components)

**File**: `/ExpenseTracker/Features/Settings/SettingsView+Sections.swift`

**Purpose**: Extract section logic for readability

**Pattern**: Composition over inheritance for large views

### CSVImportResultSheet (Sheet)

**File**: `/ExpenseTracker/Features/Settings/CSVImportResultSheet.swift`

**Purpose**: Display import results (imported, duplicates, errors)

**Layout**:
```
VStack
├── Status Icon (checkmark/exclamation)
├── Summary (imported, duplicates, errors)
└── Error List (if any)
```

---

## Service Layer

### CSVService (Static Methods)

**File**: `/ExpenseTracker/Features/Settings/CSVService.swift`

**Methods**:
- `exportExpenses(_:) -> String`
- `createTempCSVFile(content:) -> URL?`
- `importCSV(from:into:existingExpenses:existingCategories:) -> ImportResult`
- `exportExpensesAsJSON(_:) -> String`

### PDFExportService (Static Methods)

**File**: `/ExpenseTracker/Features/Settings/PDFExportService.swift`

**Methods**:
- `exportExpensesAsPDF(_:) -> Data?`
- `createTempPDFFile(data:) -> URL?`

### ExcelExportService (Static Methods)

**File**: `/ExpenseTracker/Features/Settings/ExcelExportService.swift`

**Methods**:
- `exportExpensesAsExcel(_:) -> Data?`
- `createTempExcelFile(data:) -> URL?`

### DemoDataService (Static Methods)

**File**: `/ExpenseTracker/Features/Settings/DemoDataService.swift`

**Methods**:
- `insertDemoData(modelContext:categories:) -> Int`
- `removeDemoData(modelContext:) -> Int`

---

## Navigation Patterns

### 1. Tab Navigation (Root)

User switches between features via bottom tab bar.

**Implementation**: `TabView` in `ContentView`

### 2. Modal Sheets (Add/Edit)

Full-screen sheets for creating/editing data.

**Pattern**:
```swift
@State private var showingAddSheet = false
@State private var itemToEdit: Item?

.sheet(isPresented: $showingAddSheet) {
    AddItemSheet()
}
.sheet(isPresented: $showingEditSheet) {
    if let item = itemToEdit {
        EditItemSheet(item: item)
    }
}
```

### 3. Alert Dialogs (Delete)

Confirmation dialogs for destructive actions.

**Pattern**:
```swift
@State private var showingDeleteConfirmation = false
@State private var itemToDelete: Item?

.alert("Delete Item", isPresented: $showingDeleteConfirmation) {
    Button("Delete", role: .destructive) { confirmDelete() }
    Button("Cancel", role: .cancel) { }
}
```

### 4. Menu Actions (Filters/Export)

Contextual menus in toolbar.

**Pattern**:
```swift
Menu {
    Button("Option 1") { /* action */ }
    Button("Option 2") { /* action */ }
    Divider()
    Button("Clear") { /* action */ }
} label: {
    Image(systemName: "line.3.horizontal.decrease.circle")
}
```

---

## Component Reuse

### Shared Components

1. **colorForCategory(_:) -> Color**: Global helper function
   - Used in: DashboardComponents, CategoriesView, BudgetsView
   - Maps string to Color

2. **Currency Formatting**: `.currency(code:)` formatter
   - Used everywhere amounts are displayed
   - Respects user locale

3. **Date Extensions**: `startOfMonth`, `endOfMonth`
   - Defined in Budget.swift
   - Used across Dashboard, Budgets, Filters

### Component Guidelines

1. **Extract when >3 uses**: Create shared component
2. **Keep inline when <3 uses**: Avoid premature abstraction
3. **Use ViewBuilder**: For conditional content
4. **Prefer composition**: Over complex view hierarchies

---

## State Flow

### Data Flow (Unidirectional)

```
User Action → View → ModelContext.insert/update/delete → SwiftData
    ↑                                                         ↓
    └─────────────── UI Update ←── @Query observes ──────────┘
```

### Filter Flow (Bidirectional)

```
ExpenseListView (write filters)
    ↓ @AppStorage
DashboardView (read filters)
    ↓ @AppStorage
SettingsView (read filters for export)
```

### Sheet Presentation

```
Parent View
├── @State showingSheet = false
├── Button { showingSheet = true }
└── .sheet(isPresented: $showingSheet) { SheetView() }
```

---

## Accessibility

### VoiceOver Support

All interactive elements have accessibility labels:

```swift
.accessibilityLabel("Budget for \(category.name)")
.accessibilityValue("Spent $50 of $200")
.accessibilityAddTraits(.isButton)
```

### Dynamic Type

All text respects user font size preferences:

```swift
.font(.body)        // Scales automatically
.font(.headline)    // Scales automatically
```

### Color Contrast

- Uses system colors (adapts to Dark Mode)
- Progress bars use distinct colors (green/yellow/red)
- Icons supplement color information

---

## View Lifecycle

### Typical View Lifecycle

1. **Init**: View struct created
2. **Body Evaluation**: SwiftUI calls `body` property
3. **Render**: View hierarchy built
4. **Observe**: `@Query` subscribes to SwiftData changes
5. **Update**: `body` re-evaluated when data changes
6. **Teardown**: View removed from hierarchy

### onAppear vs Task

```swift
// ✅ Use onAppear for synchronous setup
.onAppear {
    seedDefaultCategoriesIfNeeded()
}

// ✅ Use task for async operations
.task {
    await loadRemoteData()
}
```

---

## Performance Optimizations

### 1. Lazy Loading

List views use `LazyVStack` implicitly:
```swift
List {
    ForEach(expenses) { expense in
        ExpenseRowView(expense: expense)
    }
}
// Rows created on-demand as user scrolls
```

### 2. Computed Properties

SwiftUI caches computed properties:
```swift
private var filteredExpenses: [Expense] {
    expenses.filter { /* logic */ }
}
// Re-computed only when dependencies change
```

### 3. Animation Scoping

Animate specific values, not entire views:
```swift
.animation(.snappy, value: filteredExpenses.count)
// Not: .animation(.snappy) // animates everything
```

---

## Testing Views

### Preview Providers

Each view has a `#Preview`:

```swift
#Preview {
    ExpenseListView()
        .modelContainer(PreviewData.previewModelContainer)
}
```

### Preview Data

Shared in-memory container with sample data:

```swift
struct PreviewData {
    static let previewModelContainer: ModelContainer = {
        // Create in-memory container
        // Insert sample categories, expenses, budgets
    }()
}
```

---

## View Composition Best Practices

### 1. Keep Views Focused

Each view has single responsibility:
- `ExpenseListView`: Display list
- `ExpenseRowView`: Display single row
- `AddExpenseSheet`: Create/edit expense

### 2. Extract Complex Logic

Move complex calculations to model or helper:
```swift
// ❌ Bad: Complex logic in view
var body: some View {
    Text("\((expenses.reduce(0) { $0 + $1.amount } / 100) * 1.09)")
}

// ✅ Good: Logic in computed property or model
var totalWithTax: Decimal {
    expenses.reduce(0) { $0 + $1.amount } * 1.09
}
```

### 3. Use ViewBuilder

For conditional content:
```swift
@ViewBuilder
var emptyStateView: some View {
    if expenses.isEmpty {
        ContentUnavailableView(...)
    } else {
        List { ... }
    }
}
```

---

## Summary

The view hierarchy follows these principles:

1. **Tab-based root**: Five independent features
2. **Self-contained features**: Each tab is complete feature
3. **Model-driven**: Views observe SwiftData directly
4. **Shallow hierarchy**: Avoid deep nesting
5. **Component reuse**: Share via global functions or dedicated components
6. **Accessibility first**: VoiceOver, Dynamic Type, Color Contrast
7. **Performance**: Lazy loading, scoped animations, efficient queries

This architecture enables rapid feature development while maintaining clarity and testability.
