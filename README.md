# CaffeineTracker

CaffeineTracker is an iOS app built with SwiftUI that helps users track their daily caffeine intake.

## Features
- Add drinks from preset beverages (coffee, tea, energy drinks, soft drinks).
- Create custom beverages with user-defined caffeine amounts.
- Calendar view to browse past entries and see daily totals.
- Statistics screen with charts and quick summaries (daily average, streaks, etc.).
- Settings to adjust daily caffeine limit and manage saved data.

## Structure
- **Models.swift**: Core data models (`BeverageType`, `CaffeineEntry`) and helpers.
- **CaffeineIntakeManager.swift**: ObservableObject that manages entries, limits, and persistence.
- **Views**: SwiftUI screens including TodayView, CalendarView, StatsView, and SettingsView.
- **AddEntryView / AddEntryForDateView**: Forms for creating new entries.

## Usage
1. Open the app to the **Dashboard** (Today view).
2. Tap **Add Drink** to log a new entry.
3. Switch between tabs for Calendar, Stats, or Settings.
4. Swipe entries to delete them if needed.

## Requirements
- iOS 16.0+
- Xcode 15+

## Notes
- Default daily limit is 400mg, adjustable in Settings.
- Data is stored locally using `UserDefaults` for simplicity.
