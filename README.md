# 💰 ExpenseTracker-SwiftUI

A modern SwiftUI expense tracking app built with SwiftData and Swift Charts. Track your spending with beautiful visualizations, smart filtering, and comprehensive category management.

![iOS 18.0+](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-orange.svg)
![SwiftData](https://img.shields.io/badge/SwiftData-iOS18-green.svg)
![Swift Charts](https://img.shields.io/badge/Swift_Charts-5.0-red.svg)

## ✨ Features

### 📊 **Dashboard & Analytics**
- **Interactive Charts**: Monthly spending trends with 6M/12M time range toggles
- **Category Breakdown**: Pie charts showing spending distribution across categories
- **Smart Summary Cards**: Total spending, monthly trends, and top categories
- **Filter Integration**: All charts respect active date range and category filters
- **Trend Analysis**: Compare current period vs. previous with percentage changes

### 💸 **Expense Management**
- **Advanced Filtering**: Date ranges (This Month, Last 7 Days, Custom, etc.)
- **Real-time Search**: Find expenses by notes or category names instantly
- **Category Filtering**: Filter by specific categories with visual indicators
- **Dual-mode Forms**: Single form handles both adding new and editing existing expenses
- **Currency Formatting**: Proper locale-aware currency display and input
- **Swipe Actions**: Native iOS swipe-to-delete with confirmation alerts

### 🏷️ **Category System**
- **Full CRUD Operations**: Create, read, update, and delete categories
- **Color Coding**: 11 vibrant colors with visual swatches and previews
- **SF Symbols**: Searchable symbol picker with 24 curated suggestions
- **Smart Validation**: Prevent duplicate names with real-time feedback
- **Safe Deletion**: Automatic expense reassignment to "Uncategorized"
- **Protected Categories**: "Uncategorized" category cannot be deleted

### 📱 **User Experience**
- **Native iOS Design**: Uses system colors, fonts, and accessibility features
- **Haptic Feedback**: Success, impact, and notification feedback throughout
- **Accessibility First**: VoiceOver support, proper traits, and semantic labels
- **Empty States**: Contextual guidance when no data is available
- **Filter Persistence**: App remembers your filter preferences between launches
- **Keyboard Shortcuts**: Smart keyboard management with focus states

## 🏗️ Architecture

### Model-Driven SwiftUI
This app follows a **pure SwiftUI + SwiftData** architecture without ViewModels:
- `@Model` classes define the data layer with automatic persistence
- `@Query` provides reactive data fetching with sorting and filtering
- `@Environment(\.modelContext)` handles CRUD operations
- `@AppStorage` maintains user preferences and filter states

### SwiftData Benefits
- **Native SwiftUI Integration**: Designed specifically for SwiftUI's declarative approach
- **Type Safety**: Compile-time checking for relationships and queries  
- **Automatic Migration**: Schema evolution handled by the framework
- **Performance**: Optimized for iOS with lazy loading and efficient updates

### Project Structure
```
ExpenseTracker/
├── Models/                     # SwiftData @Model classes
│   ├── Category.swift          # Category model with relationships
│   └── Expense.swift           # Expense model with decimal amounts
├── Features/
│   ├── Expenses/               # Expense list, forms, and filtering
│   ├── Dashboard/              # Charts and analytics
│   ├── Categories/             # Category CRUD and management
│   └── Settings/               # App preferences and utilities
└── ExpenseTrackerTests/        # Comprehensive test coverage (14 tests)
```

## 📋 Technical Highlights

### Swift Charts Integration
- **BarMark** charts for monthly spending trends
- **SectorMark** pie charts for category breakdowns  
- **Accessibility** labels and values for all chart elements
- **Dynamic Data** updates with smooth animations

### Advanced Filtering System
- **Composite Filters**: Combine date ranges, categories, and search terms
- **Filter Persistence**: State maintained across app launches via `@AppStorage`
- **Smart UI**: Dynamic navigation titles and filter status indicators
- **Custom Date Ranges**: User-defined start and end dates

### Form Validation & UX
- **Real-time Validation**: Immediate feedback for duplicate names and invalid inputs
- **Currency Handling**: Proper `Decimal` usage for financial calculations
- **Sheet Presentation**: Modern `.presentationDetents([.medium, .large])`
- **Focus Management**: `@FocusState` for keyboard and input handling

## 🧪 Testing

Comprehensive test coverage with **14 unit tests** covering:
- Date range filtering logic and edge cases
- Category name validation and uniqueness
- Search functionality across notes and categories
- SwiftData model relationships and CRUD operations
- Filter combination scenarios and state persistence

## 🛠️ Requirements

- **iOS 18.0+** (SwiftData requirements)
- **Xcode 16.0+**
- **Swift 6.0+**

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/YourUsername/ExpenseTracker-SwiftUI.git
   cd ExpenseTracker-SwiftUI
   ```

2. **Open in Xcode**
   ```bash
   open ExpenseTracker.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd+R` to build and run
   - The app will automatically seed with sample categories on first launch

## ⚡ Development Commands

```bash
# Run tests
xcodebuild test -scheme ExpenseTracker -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Build for device
xcodebuild -scheme ExpenseTracker -configuration Release

# Clean build folder
xcodebuild clean -scheme ExpenseTracker
```

## 📸 App Structure

The app features a clean **4-tab navigation**:
- **💸 Expenses**: List, search, filter, and manage all expenses
- **📊 Dashboard**: Visual analytics with charts and spending insights  
- **🏷️ Categories**: Create and manage expense categories
- **⚙️ Settings**: App preferences and utilities

---

*Built with ❤️ using SwiftUI, SwiftData, and Swift Charts*
