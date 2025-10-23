# Developer Onboarding Guide

Welcome to ExpenseTracker-SwiftUI! This guide will help you get started as a new developer on the project.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Getting Started](#getting-started)
3. [Project Structure](#project-structure)
4. [Core Concepts](#core-concepts)
5. [Common Tasks](#common-tasks)
6. [Development Workflow](#development-workflow)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)
9. [Resources](#resources)

---

## Prerequisites

### Required Software

- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9+
- **iOS Deployment Target**: iOS 17.0+

### Recommended Tools

- **Git**: Version control
- **VS Code**: For markdown editing (optional)
- **SF Symbols App**: Browse available icons
- **Xcode Simulator**: iOS 17+ devices

### Knowledge Requirements

- **Swift**: Intermediate level
- **SwiftUI**: Basic to intermediate
- **SwiftData**: Basic (we'll teach you!)
- **Git**: Basic commands

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/JeffESchmitz/ExpenseTracker-SwiftUI.git
cd ExpenseTracker-SwiftUI
```

### 2. Open in Xcode

```bash
open ExpenseTracker.xcodeproj
```

### 3. Build and Run

1. Select a simulator (iPhone 15 Pro recommended)
2. Press `⌘R` or click the Play button
3. Wait for build to complete (~30 seconds first time)
4. App should launch in simulator

### 4. Verify Setup

The app should:
- Launch without errors
- Display a tab bar with 5 tabs
- Show "No expenses" empty state in Expenses tab
- Have 6 default categories in Categories tab

---

## Project Structure

```
ExpenseTracker-SwiftUI/
├── ExpenseTracker/
│   ├── ExpenseTrackerApp.swift      # App entry point
│   ├── ContentView.swift            # Root tab view
│   ├── Models/                      # SwiftData models
│   │   ├── Expense.swift
│   │   ├── Category.swift
│   │   ├── Budget.swift
│   │   └── PreviewData.swift
│   ├── Features/                    # Feature-specific views
│   │   ├── Expenses/
│   │   ├── Dashboard/
│   │   ├── Budgets/
│   │   ├── Categories/
│   │   └── Settings/
│   ├── Assets.xcassets/             # Images, colors, icons
│   └── Preview Content/
├── ExpenseTrackerTests/             # Unit tests
├── ExpenseTrackerUITests/           # UI tests
└── CLAUDE.md                        # AI contributor guide
```

### Key Directories

- **Models/**: SwiftData models (`@Model` classes)
- **Features/**: Views organized by feature (tab)
- **Features/*/**: Each feature has its own subdirectory
  - Main view (e.g., `ExpenseListView.swift`)
  - Sheets (e.g., `AddExpenseSheet.swift`)
  - Components (e.g., `ExpenseRowView.swift`)
  - Services (e.g., `CSVService.swift`)

---

## Core Concepts

### 1. Model-Driven Architecture

**No ViewModels!** This app uses model-driven SwiftUI:

```
Traditional MVVM:
View → ViewModel → Model (complex, redundant state)

ExpenseTracker:
View → @Query → SwiftData Model (direct, reactive)
```

**Key Benefits**:
- Less boilerplate
- Automatic UI updates
- Single source of truth

### 2. SwiftData Basics

#### Defining Models

```swift
@Model
final class Expense {
    var amount: Decimal
    var date: Date

    @Relationship
    var category: Category
}
```

#### Querying Data

```swift
// In a View
@Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
```

#### Inserting Data

```swift
// In a View
@Environment(\.modelContext) private var modelContext

let expense = Expense(amount: 42.50, date: Date(), category: category)
modelContext.insert(expense)
try modelContext.save()
```

### 3. Tab-Based Navigation

The app has 5 main tabs:

1. **Expenses**: List and manage expenses
2. **Dashboard**: Charts and analytics
3. **Budgets**: Monthly spending limits
4. **Categories**: Organize expenses
5. **Settings**: Import/export, demo data

### 4. Filter Sync Pattern

Filters set in Expenses tab are automatically applied to Dashboard and Settings exports:

```swift
// Shared via @AppStorage
@AppStorage("filterType") private var filterTypeRaw = ...
@AppStorage("selectedCategoryName") private var selectedCategoryName: String?
```

---

## Common Tasks

### Task 1: Add a New Expense

**Goal**: Understand the basic CRUD flow

**Steps**:

1. Open `ExpenseListView.swift`
2. Find the "Add" button:
   ```swift
   Button { showingAddSheet = true } label: { Image(systemName: "plus") }
   ```
3. Observe the sheet presentation:
   ```swift
   .sheet(isPresented: $showingAddSheet) {
       AddExpenseSheet()
   }
   ```
4. Open `AddExpenseSheet.swift`
5. Review the form fields and save logic
6. Run the app and add an expense

**Learning Points**:
- Sheet presentation pattern
- Form validation
- SwiftData insert
- Haptic feedback

---

### Task 2: Add a New Date Range Filter

**Goal**: Extend existing functionality

**Current Filters**:
- All Time, This Month, Last Month, Last 7 Days, Last 30 Days, Year to Date, Custom

**Your Task**: Add "Last 90 Days" filter

**Steps**:

1. Open `DateRangeFilter.swift`
2. Add new case to enum:
   ```swift
   enum DateRangeFilter: String, CaseIterable {
       // ... existing cases
       case last90Days
   }
   ```
3. Add display name:
   ```swift
   var displayName: String {
       switch self {
       // ... existing cases
       case .last90Days: return "Last 90 Days"
       }
   }
   ```
4. Implement date range logic:
   ```swift
   func dateRange(...) -> (start: Date, end: Date)? {
       switch self {
       // ... existing cases
       case .last90Days:
           return rangeForLast(days: 90, calendar: calendar, now: now)
       }
   }
   ```
5. Build and run
6. Open Expenses tab → Filter menu
7. Select "Last 90 Days"

**Learning Points**:
- Enum-based strategy pattern
- Date calculations
- Filter application

---

### Task 3: Create a New Category

**Goal**: Learn model creation and persistence

**Steps**:

1. Run the app
2. Navigate to Categories tab
3. Tap the "+" button
4. Fill in form:
   - Name: "Health"
   - Color: Pick green
   - Symbol: Search for "heart.fill"
5. Tap "Save"
6. Verify category appears in list
7. Go to Expenses tab → Add expense
8. Verify "Health" appears in category picker

**Learning Points**:
- Model relationships
- Form validation
- Symbol picker
- Data persistence

---

### Task 4: Generate and Remove Demo Data

**Goal**: Understand demo data service

**Steps**:

1. Navigate to Settings tab
2. Tap "Generate Demo Data"
3. Wait for success alert
4. Navigate to Expenses tab
5. Change filter to "All Time"
6. Observe 50-100 demo expenses
7. Navigate to Dashboard tab
8. Observe charts populated with data
9. Navigate to Settings tab
10. Tap "Remove Demo Data"
11. Confirm deletion
12. Verify data is removed

**Learning Points**:
- Service layer pattern
- Bulk data operations
- Filter integration
- `isDemo` flag pattern

---

### Task 5: Export Expenses to CSV

**Goal**: Learn export flow

**Steps**:

1. Add a few expenses (or generate demo data)
2. Navigate to Expenses tab
3. Tap the export button (up arrow)
4. Select "CSV"
5. Wait for export to complete
6. Tap the share button (appears after export)
7. Share to Notes or Files app
8. Open exported file
9. Verify format:
   ```
   date,amount,category,notes
   2025-01-15,42.50,Food,"Lunch"
   ```

**Learning Points**:
- Export service pattern
- Temporary file creation
- ShareLink integration
- Date formatting

---

## Development Workflow

### Typical Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Edit code
   - Use SwiftUI Previews for fast iteration
   - Test in simulator

3. **Write Tests** (if applicable)
   - Unit tests in `ExpenseTrackerTests/`
   - UI tests in `ExpenseTrackerUITests/`

4. **Build and Test**
   ```bash
   # Build
   xcodebuild -project ExpenseTracker.xcodeproj -scheme ExpenseTracker

   # Run tests
   xcodebuild test -project ExpenseTracker.xcodeproj -scheme ExpenseTracker \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest'
   ```

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   # Create PR on GitHub
   ```

### Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `refactor:` Code restructuring
- `test:` Adding tests
- `chore:` Tooling/infra

**Examples**:
```bash
git commit -m "feat: add last 90 days filter"
git commit -m "fix: budget calculation includes end of month"
git commit -m "docs: update API documentation"
```

---

## Testing

### Unit Tests

**Location**: `ExpenseTrackerTests/`

**Example**: Test budget calculation

```swift
func testBudgetCalculation() throws {
    let category = Category(name: "Food", color: "orange", symbolName: "fork.knife")
    let budget = try Budget(category: category, monthlyLimit: 200, currentMonth: Date())

    let expense = Expense(amount: 50, date: Date(), category: category)
    category.expenses.append(expense)

    XCTAssertEqual(budget.calculateCurrentSpending(), 50)
}
```

**Run Tests**:
- Xcode: `⌘U`
- CLI: `xcodebuild test ...`

### UI Tests

**Location**: `ExpenseTrackerUITests/`

**Example**: Test expense creation flow

```swift
func testAddExpense() throws {
    let app = XCUIApplication()
    app.launch()

    // Tap Expenses tab
    app.tabBars.buttons["Expenses"].tap()

    // Tap Add button
    app.navigationBars.buttons["Add"].tap()

    // Fill form
    app.textFields["Amount"].tap()
    app.textFields["Amount"].typeText("42.50")

    // Save
    app.buttons["Save"].tap()

    // Verify expense appears
    XCTAssert(app.staticTexts["$42.50"].exists)
}
```

### SwiftUI Previews

**Fast Iteration**: Use previews for visual testing

```swift
#Preview {
    ExpenseListView()
        .modelContainer(PreviewData.previewModelContainer)
}
```

**Run Preview**: `⌘⌥P` in Xcode

---

## Troubleshooting

### Issue: "Schema migration needed" error

**Symptom**: App crashes on launch with schema error

**Cause**: Model schema changed (added/removed properties)

**Solution**: App auto-resets database. If it persists:
```bash
# Delete app from simulator
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/ExpenseTracker-*
# Rebuild
```

---

### Issue: SwiftUI Preview not working

**Symptom**: Preview shows "Failed to build preview"

**Solution**:
1. Clean build: `⌘⇧K`
2. Rebuild: `⌘B`
3. Refresh preview: `⌘⌥P`
4. If still failing, check console for specific error

---

### Issue: Tests failing on CI but passing locally

**Symptom**: GitHub Actions reports test failures

**Cause**: Simulator differences or timing issues

**Solution**:
1. Run tests with same simulator as CI (iPhone 15 Pro)
2. Add delays for async operations
3. Check for race conditions

---

### Issue: "No such module 'Charts'" error

**Symptom**: Build fails with missing Charts module

**Cause**: Running on iOS 16 or earlier

**Solution**: Ensure deployment target is iOS 17+
1. Open project settings
2. Select "ExpenseTracker" target
3. General tab → Minimum Deployments → iOS 17.0

---

### Issue: Empty expenses list after filtering

**Symptom**: Expenses exist but list shows "No results"

**Cause**: Filters are active

**Solution**: Check filter indicator banner at top of list, tap "Clear Filters"

---

## Resources

### Documentation

- **ARCHITECTURE.md**: System architecture and data flow
- **VIEW_HIERARCHY.md**: View structure and navigation
- **CODE_QUALITY_ANALYSIS.md**: Code quality metrics
- **API_DOCUMENTATION.md**: API reference
- **BEST_PRACTICES.md**: Coding standards
- **CLAUDE.md**: AI contributor guidance

### External Resources

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Charts](https://developer.apple.com/documentation/charts)
- [SF Symbols Browser](https://developer.apple.com/sf-symbols/)

### Community

- **GitHub Issues**: Report bugs or request features
- **Pull Requests**: Contribute code
- **Discussions**: Ask questions

---

## Next Steps

Now that you're onboarded, here are some suggested next steps:

### Beginner

1. Complete all Common Tasks above
2. Read ARCHITECTURE.md
3. Add a new date range filter (Last 90 Days)
4. Write a unit test for DateRangeFilter

### Intermediate

1. Add a new export format (e.g., Markdown)
2. Implement category color customization (hex picker)
3. Add expense editing inline (without sheet)
4. Write UI tests for expense workflow

### Advanced

1. Add CloudKit sync
2. Implement recurring expenses
3. Add expense search with advanced filters
4. Create widgets for Today view

---

## Getting Help

### Internal Resources

- Review existing code and patterns
- Check documentation files
- Search GitHub issues for similar problems

### Asking Questions

When asking for help, include:

1. **What you're trying to do**: "I want to add a new chart to the dashboard"
2. **What you've tried**: "I added a new view but it's not showing data"
3. **Error messages**: Copy-paste full error from console
4. **Screenshots**: If UI-related
5. **Code snippet**: Minimal reproducible example

### Example Good Question

```
Hi! I'm trying to add a line chart to the dashboard showing spending trends.

I created a new LineChartView component and added it to DashboardView:

```swift
struct LineChartView: View {
    let monthlyData: [MonthlyData]

    var body: some View {
        Chart(monthlyData, id: \.month) { data in
            LineMark(
                x: .value("Month", data.monthName),
                y: .value("Amount", data.amount)  // ERROR HERE
            )
        }
    }
}
```

But I'm getting this error:
"Cannot convert value of type 'Decimal' to expected argument type 'Double'"

How do I convert Decimal to Double for the chart?
```

**Answer**: Use `Double(truncating: data.amount as NSDecimalNumber)`

---

## Welcome!

You're now ready to contribute to ExpenseTracker-SwiftUI! If you have questions or get stuck, don't hesitate to reach out. Happy coding!

---

## Appendix: Common Patterns

### Pattern 1: Adding a New View

```swift
// 1. Create view file
// ExpenseTracker/Features/MyFeature/MyView.swift

import SwiftUI
import SwiftData

struct MyView: View {
    @Query private var expenses: [Expense]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                ForEach(expenses) { expense in
                    Text(expense.notes ?? "")
                }
            }
            .navigationTitle("My View")
        }
    }
}

#Preview {
    MyView()
        .modelContainer(PreviewData.previewModelContainer)
}
```

### Pattern 2: Adding a New Sheet

```swift
// Parent View
struct ParentView: View {
    @State private var showingSheet = false
    @State private var selectedItem: Item?

    var body: some View {
        Button("Show Sheet") {
            showingSheet = true
        }
        .sheet(isPresented: $showingSheet) {
            MySheet(item: selectedItem)
        }
    }
}

// Sheet View
struct MySheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: Item?

    var body: some View {
        NavigationStack {
            Form {
                // Form fields
            }
            .navigationTitle(item == nil ? "Add" : "Edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save logic
                        dismiss()
                    }
                }
            }
        }
    }
}
```

### Pattern 3: Adding a New Model

```swift
// 1. Define model
@Model
final class MyModel {
    var name: String
    var date: Date

    @Relationship
    var relatedItem: RelatedModel

    init(name: String, date: Date, relatedItem: RelatedModel) {
        self.name = name
        self.date = date
        self.relatedItem = relatedItem
    }
}

// 2. Add to schema
// ExpenseTrackerApp.swift
.modelContainer(for: [Expense.self, Category.self, Budget.self, MyModel.self])

// 3. Query in view
@Query private var myModels: [MyModel]

// 4. Insert
let model = MyModel(name: "Test", date: Date(), relatedItem: item)
modelContext.insert(model)
try modelContext.save()
```

### Pattern 4: Adding a New Service

```swift
// Services are static structs with static methods
struct MyService {
    static func doSomething(with data: [Item]) -> Result {
        // Business logic
        return result
    }

    static func processData(input: String) -> Output? {
        // Processing logic
        return output
    }
}

// Usage in view
let result = MyService.doSomething(with: items)
```

---

**Last Updated**: 2025-01-23
**Version**: 1.0
