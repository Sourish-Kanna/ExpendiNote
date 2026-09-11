# ExpendiNote 📝

<!-- Badges -->
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org)
[![Material 3](https://img.shields.io/badge/Material--3-7B1FA2?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)

> **A minimalist personal finance tracker designed for fast daily expense logging and a clear understanding of personal spending.**

I initially built ExpendiNote as a focused, one-time personal project to make recording everyday expenses quick and frictionless. After using it regularly myself, I discovered usability issues, missing capabilities, and areas where the application could be substantially better.

That led me to expand the original scope for **v2.0.0**. My goal now is to address those real-world findings, improve the overall experience, and complete the expanded scope properly rather than continuously adding features without a clear direction.

This repository contains the full Flutter source code for the Android application.

---

## 📲 Try It Out

**v1.2.1 is the latest stable release.** You can download and install the ready-to-run Android application directly from the Releases page:

👉 **APK available via GitHub Releases**

[![Download Latest APK](https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](https://github.com/Sourish-Kanna/ExpendiNote/releases/latest)

**v2.0.0 is currently in development.**

---

## 📖 Context

> *Most finance apps are over-engineered with complex bank integrations, making simple manual logging feel like a chore.*

I built ExpendiNote to solve the friction of manual expense tracking. I deliberately focus on the essentials:

- **Speed**: Log an expense in seconds.
- **Privacy**: Local-first storage using SQLite; your data stays on your device unless you explicitly choose to export or share it.
- **Simplicity**: A clean Material 3 interface that keeps everyday spending easy to record and understand.
- **Practicality**: I shape features around actual usage rather than trying to turn ExpendiNote into an all-in-one banking application.

As I used the application in real life, the scope naturally expanded based on what I found useful, missing, or frustrating. v2.0.0 is focused on addressing those findings and bringing the expanded scope to a complete, polished state.

---

## ✨ Features

### Core Capabilities

- **Rapid Entry**: Log titles, amounts, categories, optional descriptions, and custom dates.
- **Activity Feed**: View recent transactions directly from the home screen.
- **Category Management**: Create, edit, organize, pin, merge, and manage categories.
- **Search**: Find transactions using relevant transaction information.
- **Drill-Down Navigation**: Navigate from summaries to the individual transactions contributing to them.
- **Daily & Monthly Summaries**: Understand spending activity across different time periods.

### Data & UX

- **Offline Support**: Fully functional without an internet connection using local SQLite persistence.
- **Material 3 UI**: Built using Material 3 with a centralized theme architecture.
- **Custom Themes**: System, light, and dark theme modes with selectable custom theme colors.
- **Local Data**: Spending data is stored locally on the device.
- **Data Export**: Export spending data for portability and external use.
- **Reactive UI**: Changes to transactions and settings are reflected across relevant parts of the application.

---

## 🧠 Engineering Highlights

### 1. Unified Filter Architecture

The application uses reusable filtering and history components to support different ways of viewing transactions without duplicating separate implementations for every filtering scenario.

### 2. Reactive State Management

I use lightweight reactive state management to keep relevant screens synchronized when transaction or application settings change, without requiring unnecessary full-screen refreshes.

### 3. Structured Local Persistence

I use SQLite with a versioned database schema and explicit migrations, allowing the data model to evolve while preserving existing user data across application updates.

### 4. Centralized Theme Architecture

Material 3 theming is centralized through a dedicated theme architecture, supporting system/dynamic colors, custom theme colors, light/dark modes, and consistent component styling throughout the application.

---

## 🧑‍💼 What This Project Demonstrates

This repository demonstrates:

- **Flutter Framework Proficiency**: Building a complete Android application with Flutter and Dart.
- **Database Design**: SQLite integration with versioned schema migrations, relationships, indexing, and structured repositories.
- **Modern UI/UX**: Material 3 components and a centralized design system.
- **State Management**: Lightweight reactive state management suitable for a local-first application.
- **System Thinking**: Evolving a small application based on actual usage while keeping the architecture maintainable.
- **Product Development**: Moving from an initial focused idea toward a broader, user-driven product scope.

---

## 🏗 Tech Stack

### Core

- **Language**: Dart
- **Framework**: Flutter
- **Persistence**: SQLite (via `sqflite`)

### Tooling

- **State Management**: ValueNotifier / Change Notification
- **Data Export**: CSV and sharing utilities
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
git clone https://github.com/Sourish-Kanna/ExpendiNote.git
cd ExpendiNote

# Install dependencies
flutter pub get

# Run the app (ensure an emulator or device is connected)
flutter run
```

---

## 🌿 Project Status

- **Latest Stable Release**: v1.2.1
- **Next Release**: v2.0.0
- **Current Status**: v2.0.0 in development
- **Current Focus**: UI/UX redesign, usability improvements, and completion of the expanded project scope.

I originally intended ExpendiNote to be a focused, one-time project. Continued real-world usage showed me that there was more worth improving, which led to the expanded v2.0.0 scope.

My goal for v2.0.0 is to bring that expanded scope to a polished and complete state rather than continuously adding features without a defined direction.

---

## 🔮 Future Planned Scopes

The following are longer-term ideas that I may explore after the core v2.0.0 scope is completed:

- Further usability improvements based on real-world usage
- Additional budgeting capabilities
- Advanced spending visualizations
- Intelligent spending insights and analytics
- Local notifications and reminders
- Optional future integrations or enhancements

These are **future possibilities, not commitments for v2.0.0**.

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
