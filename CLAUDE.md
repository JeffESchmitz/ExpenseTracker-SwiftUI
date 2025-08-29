# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview
ExpenseTracker-SwiftUI is a SwiftUI-based iOS application for expense tracking.

- **Language:** Swift 5.9+
- **iOS Deployment Target:** iOS 17+ (Xcode 15/16 toolchain)
- **UI Framework:** SwiftUI with SwiftUI Previews enabled
- **Persistence:** SwiftData (preferred) — Core Data only if needed
- **Devices:** iPhone + iPad (Universal)
- **Testing:** Unit + UI tests using XCTest (not Swift Testing unless explicitly migrated)

---

## Project Structure
```
ExpenseTracker.xcodeproj/          # Xcode project file
ExpenseTracker/                    # Main app source code
├── ExpenseTrackerApp.swift        # App entry point
├── ContentView.swift              # Entry view
├── Assets.xcassets/               # App icons and assets
├── Models/                        # SwiftData model definitions (@Model types)
├── Features/                      # Feature-specific views (Dashboard, Expenses, Categories, Settings)
├── State/                         # Lightweight shared state containers (@Observable), if needed
├── Views/                         # Reusable SwiftUI components
└── Preview Content/               # SwiftUI preview assets
ExpenseTrackerTests/               # Unit tests
ExpenseTrackerUITests/             # UI tests
.github/workflows/                 # CI configuration
CLAUDE.md                          # AI contributor guidance
```

> Note: We intentionally avoid MVVM. This app is **model-driven SwiftUI**: views read/write `@Model` data directly via SwiftData.

---

## Development Commands

### Building and Running
- Build: ⌘B or `xcodebuild`
- Run on Simulator: ⌘R
- Run tests: ⌘U or `xcodebuild test -project ExpenseTracker.xcodeproj -scheme ExpenseTracker -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest'`

### Testing
- Unit tests: `ExpenseTrackerTests/`
- UI tests: `ExpenseTrackerUITests/`
- CI runs tests automatically on PRs

---

## Workflow & Contribution Rules

- **Branching**
  - `main` is protected (no direct commits).
  - Create feature branches: `feature/...`, `fix/...`, `chore/...`, `ci/...`.
- **Commits**
  - Use [Conventional Commits](https://www.conventionalcommits.org/):
    - `feat:` new feature  
    - `fix:` bug fix  
    - `chore:` tooling/infra changes  
    - `ci:` workflows and automation  
    - `docs:` documentation only  
    - `refactor:` internal restructuring, no behavior change
- **Pull Requests**
  - All changes via PRs into `main`.
  - Each PR must build and pass tests in CI.
  - Each PR should reference its GitHub Issue.

---

## Coding Standards (No MVVM)

- Prefer **model-driven SwiftUI**:
  - Use SwiftData `@Model` types as the single source of truth.
  - Use `@Query` to fetch models in views and `@Environment(\.modelContext)` to insert/update/delete.
  - Use `@Bindable` to edit models inline where appropriate.
- Use **lightweight shared state** only when necessary:
  - Add `@Observable` containers in `State/` for cross-feature UI state (e.g., filters, settings), not as ViewModels.
- Concurrency:
  - Use `async/await` for IO-like tasks (imports/exports), keep UI updates on the main actor.
- UI & UX:
  - Use **Apple Charts** for visualizations.
  - Support **Dark Mode**, **Dynamic Type**, and basic **VoiceOver** labels for interactive elements.
  - Use **SF Symbols** for icons; store category colors as strings/asset names and map to `Color` at the edge.
- Error handling:
  - Fail gracefully with user-visible alerts where appropriate; log non-fatal errors in development.
- Previews:
  - Provide `#Preview` samples with in-memory containers where possible for quick iteration.

---

## CI/CD

- GitHub Actions workflows in `.github/workflows/`.
- Pipeline:
  - Build on macOS runner.
  - Run `xcodebuild test` on iOS Simulator.
  - Future: add SwiftLint + coverage reporting.
- Branch protections: PRs into `main` require CI green.

---

## Tooling Integration

- **MCP Server: `XCodeBuildMCP`**
  - Runs inside a `colima` Docker instance on the developer machine.
  - Provides Claude Code with the ability to invoke `xcodebuild` commands, run builds, and execute tests programmatically.
  - This allows:
    - Verifying builds/tests directly from within Claude Code.
    - Faster iteration and reduced manual command running.
  - Usage: Claude may call into this tool for `xcodebuild build`, `xcodebuild test`, or diagnostic commands.
  - Note: Local Xcode must still be installed for simulator runs; MCP simply proxies commands.

---

## Current State
- Repo initialized and scaffolded.
- `feature/swiftdata-setup` branch is active for first feature: SwiftData models + container setup.
- Ready for incremental development via issues + branches.
- You know how to make PR's. Only ask me for help with creating a PR if you need questions answered. You are hearby allowed to create PR's if I give you the command in the intitial plan instructions. ok?