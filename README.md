# 📊 Work Tracker

<p align="center">
  <img src="assets/github/banner.png" alt="Work Tracker Banner" width="100%">
</p>

<h3 align="center">
Offline-first Flutter application for managing Jobs, Shifts, Income, Expenses and Analytics.
</h3>

<p align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter\&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart\&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?logo=sqlite\&logoColor=white)
![Provider](https://img.shields.io/badge/Provider-State%20Management-success)
![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android\&logoColor=white)
![Version](https://img.shields.io/badge/Version-v1.1.0-success)
![License](https://img.shields.io/badge/License-MIT-green)

</p>

---

# ✨ Overview

**Work Tracker** is an offline-first Flutter application designed to help freelancers, delivery drivers, part-time workers, and anyone with multiple jobs manage their work efficiently.

Instead of only tracking working hours, Work Tracker lets users manage:

* Multiple jobs
* Daily shifts
* Multiple income records per shift
* Expenses per shift
* Tips
* Profit calculation
* Dashboard
* Analytics

Everything is stored locally using **SQLite**, allowing the application to work completely offline.

---

# 🎬 Demo

> Replace these placeholders with your own GIF recordings.

| Dashboard                      | Shift Detail               |
| ------------------------------ | -------------------------- |
| ![](assets/demo/dashboard.gif) | ![](assets/demo/shift.gif) |

| Income                      | Analytics                      |
| --------------------------- | ------------------------------ |
| ![](assets/demo/income.gif) | ![](assets/demo/analytics.gif) |

---

# 📱 Screenshots

| Dashboard                             | Work                             |
| ------------------------------------- | -------------------------------- |
| ![](assets/screenshots/dashboard.png) | ![](assets/screenshots/work.png) |

| Shift                             | Shift Detail                             |
| --------------------------------- | ---------------------------------------- |
| ![](assets/screenshots/shift.png) | ![](assets/screenshots/shift_detail.png) |

| Income                             | Expense                             |
| ---------------------------------- | ----------------------------------- |
| ![](assets/screenshots/income.png) | ![](assets/screenshots/expense.png) |

| Analytics                             | Settings                             |
| ------------------------------------- | ------------------------------------ |
| ![](assets/screenshots/analytics.png) | ![](assets/screenshots/settings.png) |

---

# 🚀 Features

## 📊 Dashboard

* Daily overview
* Total Income
* Total Expense
* Net Profit
* Active Shift counter
* Quick actions

---

## 💼 Work Management

* Create work
* Edit work
* Delete work
* Custom icon
* Custom color
* Multiple works

Example

```
Grab Driver

ShopeeFood

Freelance Developer

Coffee Shop
```

---

## 🕒 Shift Management

Each work can contain multiple shifts.

Features

* Create Shift
* Edit Shift
* Delete Shift
* Timeline
* Notes
* Start Time
* End Time

---

## 💰 Income Management

Each Shift supports unlimited Income records.

Example

```
Order #001

+120.000đ

Tip +20.000đ

-------------------

Order #002

+95.000đ

Tip +10.000đ
```

Income supports

* Title
* Amount
* Tip
* Note
* Created Time

CRUD

* ✅ Create
* ✅ Read
* ✅ Update
* ✅ Delete

---

## 💸 Expense Management

Every Shift also supports unlimited expenses.

Example

```
Gas

35.000đ

----------------

Parking

10.000đ

----------------

Lunch

45.000đ
```

Expense supports

* Title
* Amount
* Note

CRUD

* ✅ Create
* ✅ Read
* ✅ Update
* ✅ Delete

---

## 📈 Shift Summary

Every Shift automatically calculates

```
Orders

Income

Tips

Expenses

Net Profit
```

Formula

```
Profit

=

Income

+

Tips

-

Expenses
```

Everything updates automatically after every CRUD operation.

---

## 📊 Analytics

Current Analytics

* Income Chart
* Expense Summary
* Profit Summary
* Best Performing Work
* Total Income
* Total Expense
* Shift Statistics

---

## ⚙️ Settings

* Preferences
* Export Service
* Application Settings

---

# 🏗 Project Architecture

```
lib/

├── core/
│
│   ├── database/
│   ├── router/
│   ├── theme/
│   └── utils/
│
├── shared/
│
│   ├── widgets/
│   └── constants/
│
├── features/
│
│   ├── dashboard/
│   ├── work/
│   ├── shift/
│   ├── income/
│   ├── expense/
│   ├── analytics/
│   └── settings/
```

Every feature follows the same architecture

```
model/

repository/

provider/

screen/

widgets/
```

Architecture Pattern

```
UI

↓

Provider

↓

Repository

↓

SQLite Database
```

---

# 🗄 Database

Database

```
SQLite
```

Current Version

```
7
```

Tables

```
works

shifts

income

expense
```

Migration strategy

* Safe database migration
* Existing user data is preserved across updates

---

# 🧪 Testing

Verification

* ✅ flutter analyze
* ✅ flutter test
* ✅ APK Build

Regression coverage

* Dashboard
* Analytics
* Work
* Shift
* Income
* Expense
* Shift Summary

---

# 🛠 Tech Stack

* Flutter
* Dart
* SQLite
* Provider
* Material 3
* UUID

---

# 📌 Current Status

Current Version

```
v1.1.0
```

Development Status

🟢 Stable

Progress

```
███████████░░░░░░░░ 55%
```

---

# 🗺 Roadmap

## ✅ Version 1.0.0

* Dashboard
* Work Management
* Shift Management
* Timeline
* Analytics
* Settings

---

## ✅ Version 1.1.0

* Income Module
* Expense Module
* Shift Detail
* Shift Summary
* Income CRUD
* Expense CRUD
* Profit Calculation
* Database Migration
* Stability Improvements

---

## 🚧 Version 1.2.0

Planned

* Income Categories
* Expense Categories
* Calendar View
* Monthly Report
* CSV Export
* PDF Export
* Better Analytics
* Filter & Search
* Dark Mode

---

## 🚧 Version 1.3.0

Planned

* Backup & Restore
* Google Drive Backup
* Cloud Sync
* Multiple Currency
* Widgets
* Notification Reminder

---

## 🎯 Version 2.0.0

Long-term Goals

* Personal Finance
* Family Finance
* Budget Planning
* Saving Goals
* Investment Tracking
* Loan Management
* Multi-device Synchronization

---

# 📈 Changelog

## v1.1.0

### Added

* Income Module
* Expense Module
* Shift Detail
* Shift Summary
* Income CRUD
* Expense CRUD

### Improved

* Analytics
* Database Migration
* Provider Architecture
* Dashboard Stability
* Empty State Handling

### Fixed

* Infinite loading spinner
* Analytics loading issue
* Dashboard loading issue
* Work creation regression
* Provider refresh issues
* UI regressions

---

# 🤝 Contributing

Contributions are welcome.

Steps

1. Fork this repository
2. Create your feature branch
3. Commit your changes
4. Push your branch
5. Open a Pull Request

---

# 📄 License

This project is licensed under the MIT License.

---

# 👨‍💻 Author

**Phạm Đức Duy Tiến**

Flutter Developer

If you find this project useful, consider giving it a ⭐ on GitHub.

---

<p align="center">
Made with ❤️ using Flutter
</p>
