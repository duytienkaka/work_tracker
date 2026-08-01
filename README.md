# Work Tracker

Flutter application for tracking work shifts, income, expenses, and profit.

Work Tracker is a clean, local-first productivity app built with Flutter. It helps users manage jobs, record shifts, review performance, and understand profitability without relying on any cloud service.

## Features

- Work Management
- Shift Management
- Dashboard
- Timeline
- Analytics
- Settings
- CSV Export

## Architecture

The application uses a simple layered structure:

```text
Flutter
  ↓
Provider
  ↓
Repository
  ↓
SQLite
```

This keeps UI, state, and persistence responsibilities separated while remaining easy to extend.

## Project Structure

```text
lib/
  core/
    database/
  features/
    analytics/
    home/
    settings/
    shift/
    timeline/
    work/
  shared/
    widgets/
  theme/
main.dart
```

## Technology Stack

- Flutter
- Dart
- SQLite
- Provider
- SharedPreferences
- Material 3

## Screenshots

Placeholder images for key screens:

- [Splash](assets/screenshots/splash.md)
- [Home](assets/screenshots/home.md)
- [Work](assets/screenshots/work.md)
- [Shift](assets/screenshots/shift.md)
- [Timeline](assets/screenshots/timeline.md)
- [Analytics](assets/screenshots/analytics.md)
- [Settings](assets/screenshots/settings.md)

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Quality checks

```bash
flutter analyze
flutter test
```

### Build release APK

```bash
flutter build apk --release
```

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Changelog](CHANGELOG.md)
- [Contributing Guide](CONTRIBUTING.md)

## Roadmap

### v1.0.0

Completed:
- Work management
- Shift management
- Dashboard
- Timeline
- Analytics
- Settings
- CSV export
- Material 3 UI
- Widget tests

### v1.1

Planned:
- Advanced filtering
- Monthly reporting
- Backup and restore
- Notifications
- Additional currency support

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Author

Maintained by duytienkaka (duytienkaka123az@gmail.com).

Flutter Developer

---

## ❤️ Acknowledgements

Thanks to the Flutter community and everyone who contributed ideas and feedback during the development of Work Tracker.
