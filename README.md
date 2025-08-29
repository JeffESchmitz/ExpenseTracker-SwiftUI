# ExpenseTracker-SwiftUI
A sleek SwiftUI app to tame your spending and make tracking expenses feel effortless.

## Features

### ✅ Implemented
- **SwiftData Persistence**: Modern data layer with `@Model` classes and automatic seeding
- **Expense List & Search**: View all expenses with real-time search by category or notes
- **Add/Edit Expense Form**: Comprehensive form with currency formatting, validation, and dual-mode support
- **Category Management**: Predefined expense categories with colors and SF Symbols
- **Swipe to Delete**: Native iOS swipe gestures with confirmation alerts
- **Tap to Edit**: Quick editing by tapping any expense row
- **Accessibility**: Proper traits and labels for screen readers
- **Haptic Feedback**: Success notifications and tactile confirmations

### 🚧 Planned
- Dashboard with spending charts and analytics
- Category filtering and management
- CSV export/import functionality
- Settings and demo mode
- Advanced filters and sorting options

## Architecture

### Why SwiftData?
This app uses **SwiftData** for persistence instead of Core Data because:
- **Native SwiftUI integration**: SwiftData is designed from the ground up to work seamlessly with SwiftUI's declarative syntax
- **Model-driven architecture**: Direct binding to `@Model` objects eliminates the need for ViewModels and complex state management
- **Simplified relationships**: Clean, type-safe relationships between models without complex Core Data setup
- **Modern Swift**: Takes advantage of Swift's latest features like property wrappers and result builders
