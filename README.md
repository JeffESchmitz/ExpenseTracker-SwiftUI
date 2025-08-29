# ExpenseTracker-SwiftUI
A sleek SwiftUI app to tame your spending and make tracking expenses feel effortless.

## Architecture

### Why SwiftData?
This app uses **SwiftData** for persistence instead of Core Data because:
- **Native SwiftUI integration**: SwiftData is designed from the ground up to work seamlessly with SwiftUI's declarative syntax
- **Model-driven architecture**: Direct binding to `@Model` objects eliminates the need for ViewModels and complex state management
- **Simplified relationships**: Clean, type-safe relationships between models without complex Core Data setup
- **Modern Swift**: Takes advantage of Swift's latest features like property wrappers and result builders
