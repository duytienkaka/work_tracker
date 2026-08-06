# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by **Keep a Changelog**, and this project follows **Semantic Versioning**.

---

## [2.0.0] - 2026-08-07

### Added

* Complete Material 3 redesign across Dashboard, Works, Work Detail, Timeline, Shift List, Shift Detail, Forms, Settings and Splash.
* Today Mode with live shift progress and remaining time.
* Weekly Calendar view with day selection and daily shift summaries.
* Local shift notifications scheduled 30 minutes before a shift.
* Local Shift Templates for quickly reusing work times and notes.
* Work Insights with trends, work comparisons and profit summaries.
* Offline JSON backup and restore for Works, Shifts, Income and Expenses.
* Android home-screen widget showing the next shift state.
* Android launcher Quick Action for creating a new shift.
* Dark mode, improved empty/loading/error states and accessible touch targets.

### Changed

* Reworked navigation, typography, spacing, cards, forms, FABs and dialogs into one consistent Android design system.
* Added database-level protection against overlapping shifts across all works.
* Improved one-handed workflows and immediate CRUD refresh behavior.

### Notes

* Restore currently uses the latest local backup stored by Work Tracker.

---

## [1.3.2] - 2026-08-04

### Fixed

* Added **Edit** and **Delete** actions for Shift.
* Added confirmation dialog before deleting a Shift.
* Deleting a Shift now removes all related Income and Expense records.
* Prevented overlapping shifts within the same Work.
* Added validation requiring Start Time and End Time for Hourly and Daily work types.
* Freelance shifts remain optional for time input.
* Improved validation messages during Shift creation and editing.
* Refined the Settings screen for a more consistent UI.

### Changed

* Improved Shift creation workflow.
* Improved overall UX consistency.

---

## [1.3.1] - 2026-08-04

### Added

* Floating action button in Work Detail for easier one-handed usage.
* Vietnamese localization across the application.
* Work-type-aware labels for manual income entries.
* Better handling of Active Shift selection.

### Changed

* Removed Analytics page from the main navigation (reserved for future development).
* Improved Active Shift detection logic.
* Updated Work Detail workflow and navigation.

### Fixed

* Fixed incorrect Active Shift selection when multiple shifts exist on the same day.
* Improved manual income presentation for Hourly and Daily jobs.
* Various UI consistency improvements.

---

## [1.3.0] - 2026-08-03

### Added

* Work Type system:

  * Freelance
  * Hourly
  * Daily
* Salary Engine.
* Automatic salary generation for Hourly and Daily jobs.
* Generated Income protection.
* Shift Summary engine.

### Changed

* Refactored Shift calculation flow.
* Centralized salary calculation logic.
* Simplified Work Type architecture.

---

## [1.2.0] - 2026-08-02

### Added

* Expense management.
* Expense CRUD.
* Shift Summary.
* Profit calculation.
* Real-time synchronization between Income, Expense, Dashboard and Timeline.

### Changed

* Unified Money Formatter.
* Improved Work Detail UI.
* Improved Shift Detail UI.

---

## [1.1.0] - 2026-08-01

### Added

* Income CRUD.
* Shift Detail page.
* Income validation.
* Provider-based income management.

### Changed

* Improved Shift workflow.
* Improved Work Detail experience.

---

## [1.0.0] - 2026-07-31

### Initial Release

Features included:

* Work management
* Shift management
* Timeline
* Dashboard
* Local SQLite storage
* Settings
* Export support
* Provider architecture
* Material 3 UI
