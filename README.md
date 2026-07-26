# ExpendiNote 📝

<!-- Badges -->
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org)
[![Material 3](https://img.shields.io/badge/Material--3-7B1FA2?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)

> **A minimalist personal finance tracker designed for rapid daily spending logging and long-term analysis.**

ExpendiNote is a mobile application that simplifies the process of tracking daily expenses. It provides immediate visibility into daily and monthly spending while offering deep-dive analysis through category-wise and temporal summaries. This repository contains the full Flutter source code for the Android application.

---

## 📲 Try It Out

The project is currently stable. You can download and install the ready-to-run Android application directly from the Releases page:

👉 **APK available via GitHub Releases**

[![Download Latest APK](https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](https://github.com/Sourish-Kanna/ExpendiNote/releases/latest)

---

## 📖 Context

> *Most finance apps are over-engineered with complex bank integrations, making simple manual logging feel like a chore.*

ExpendiNote was built to solve the friction of manual expense tracking. It focuses on:

- **Speed**: Log an expense in seconds.
- **Privacy**: Local-first storage using SQLite; your data never leaves your device unless you choose to export it.
- **Simplicity**: A clean Material 3 interface that prioritizes current activity while keeping deep analysis just a tap away.

---

## ✨ Features

### Core Capabilities

- **Rapid Entry**: Log titles, amounts, and categories with optional descriptions and custom date selection.
- **Activity Feed**: View the most recent 20 entries immediately on the home screen.
- **Analysis Hub**: Consolidate spending views into Top Categories, Monthly Trends, and Daily Activity.
- **Global Search**: Instantly find specific transactions by title or category.
- **Drill-Down Navigation**: Tap any summary card to view the specific individual entries contributing to that total.

### Data & UX

- **Offline Support**: Fully functional without an internet connection using local SQLite persistence.
- **Material 3 UI**: Uses the latest design system with `surfaceContainer` palettes for a modern, layered aesthetic.
- **CSV Portability**: Share your entire spending history as a formatted CSV file at any time.
- **Reactive UI**: Real-time data synchronization across all tabs using a global state notification system.

---

## 🧠 Engineering Highlights

### 1. Unified Filter Architecture

The `HistoryScreen` operates as a generalized filtering engine. Instead of creating separate screens for "Category View" or "Month View," a single component handles dynamic predicates (Date, Category, or Month), significantly reducing code duplication and ensuring UI consistency across the entire app.

### 2. Reactive State Management

Implemented a lightweight `ValueNotifier` system to bridge the gap between the Home activity and Analysis summaries. This ensures that adding a transaction in one tab instantly updates the totals and charts in the other without requiring expensive full-database polls or manual refreshes.

### 3. Future-Ready Persistence

While completely local-first, the database schema is designed with atomic transactions and ISO-8601 date handling, making it ready for potential future cloud-sync integrations or encrypted backup features.

---

## 🧑‍💼 What This Project Demonstrates

This repository demonstrates:

- **Flutter Framework Proficiency**: Advanced use of Slivers, CustomScrollViews, and IndexedStack navigation.
- **Database Design**: Proper SQLite integration with `sqflite`, including complex grouping and ordering queries.
- **Modern UI/UX**: Implementation of Material 3 components like `SegmentedButton`, `SearchBar`, and `NavigationBar`.
- **System Thinking**: Balancing immediate user needs (fast entry) with long-term data utility (CSV export and trend analysis).

---

## 🏗 Tech Stack

### Core

- **Language**: Dart
- **Framework**: Flutter
- **Persistence**: SQLite (via `sqflite`)

### Tooling

- **State Management**: ValueNotifier / Change Notification
- **Data Export**: `csv` and `share_plus`
- **Logging**: `logger`
- **Formatting**: `intl` (Internationalization and Date Formatting)

---

## 🚀 Getting Started (Developers)

### Prerequisites

- Flutter SDK: `^3.11.5`
- Android Studio / VS Code with Flutter extensions

### Setup

```bash
# Clone the repository
git clone [https://github.com/your-username/ExpendiNote.git](https://github.com/your-username/ExpendiNote.git)
cd ExpendiNote

# Install dependencies
flutter pub get

# Run the app (ensure an emulator or device is connected)
flutter run

```

---

## 🌿 Project Status

- **Status**: Stable / Complete
- **Current Build**: Production-ready APK available in Releases.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/NewFeature`)
3. Commit your changes (`git commit -m 'Add some NewFeature'`)
4. Push to the branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

---

## 📄 License

MIT License

---

<div align="center">
  Made with ❤️ for better financial habits.
</div>
