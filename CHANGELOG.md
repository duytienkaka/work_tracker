# Changelog

All notable changes to this project will be documented in this file.

---

## [1.3.1] - 2026-08-04

### Fixed

- Fixed Active Shift selection logic.
- Fixed Dashboard incorrectly showing "No Shift".
- Fixed Work deletion leaving orphan Shift/Income/Expense data.
- Fixed Summary Card overflow.
- Fixed money formatter rounding display.

### Changed

- Improved Work and Shift workflow.
- Unified realtime refresh after CRUD operations.
- Vietnamese localization across the UI.
- Replaced top AppBar add buttons with Floating Action Button.
- Simplified Shift creation flow.
- Improved generated salary handling.

---

## [1.3.0] - 2026-08-04

### Added

- Work Type system
  - Freelance
  - Hourly
  - Daily
- Salary Engine
- Auto-generated Salary Income
- Generated Income protection
- Shift Summary Engine

### Changed

- Shift calculation moved to Salary Engine.
- Work type determines salary calculation automatically.

---

## [1.2.0]

### Added

- Expense Management
- Expense CRUD
- Expense Provider
- Expense Repository
- Shift Summary
- Realtime synchronization

---

## [1.1.0]

### Added

- Income CRUD
- Shift Detail
- Income Management
- Provider architecture improvements

---

## [1.0.0]

### Added

- Work Management
- Shift Management
- Dashboard
- Timeline
- Local SQLite database