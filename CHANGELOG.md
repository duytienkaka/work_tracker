# Changelog

## v1.1.0

### Added
- Redesigned dashboard with today's revenue, orders, profit, active shift, recent orders, quick actions, mini charts, and recent expenses
- Direct dashboard shortcuts for new shift, new work, analytics, timeline, and settings
- Release verification coverage for dashboard and analytics provider behavior

### Changed
- Refreshed the main home experience with a cleaner Material 3 layout
- Updated app version to 1.1.0+1

### Fixed
- Removed dead dashboard wrapper logic and cleaned dashboard imports
- Cleared release-time analyzer issues introduced during the dashboard upgrade

## v1.0.0

### Added
- Work management with create, edit, and delete flows
- Shift logging with optional end time, income, expense, and notes
- Dashboard summaries for income, expense, profit, and shift count
- Timeline view for chronological shift history
- Analytics screen with income and performance insights
- Settings screen with theme, currency, and export support
- Local SQLite persistence for all app data
- Widget tests for core screens

### Changed
- Refined the app flow for shift creation and editing
- Improved navigation between home, work, shift, and analytics views
- Updated the UI to a more polished Material 3 presentation

### Fixed
- Fixed refresh behavior after saving or editing shifts
- Corrected work and shift detail flows for better consistency
- Improved list and summary behavior across dashboard and analytics views
