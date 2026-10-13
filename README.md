# LifeLoop — Flutter / Dart Android App

LifeLoop is a practical “life maintenance radar” for recurring real-world responsibilities that are easy to forget: replacing a water filter, checking smoke alarms, renewing a document, servicing a bike, or restocking first-aid supplies.

Instead of being another generic to-do list, it groups tasks by the part of life they protect and makes the next useful action obvious.

## Included

- A polished dashboard with overdue, due-soon, and upcoming summaries
- Home, Health, Vehicle, Documents, and Personal categories
- Add, edit, complete, and delete recurring reminders
- Optional repeat intervals in days
- Local persistence using `shared_preferences`
- Search and category filtering
- Seeded examples so the app is useful immediately
- Responsive Material 3 UI with a dark teal / warm cream visual system

## Run on Android

This archive contains the app's Flutter source and configuration. To generate the platform-specific Android runner files on your computer:

1. Install Flutter and Android Studio, and verify with `flutter doctor`.
2. Extract this folder.
3. Open a terminal in this folder and run:

   ```bash
   flutter create --platforms=android .
   flutter pub get
   flutter run
   ```

   If Flutter asks whether to overwrite existing files, keep this folder's `lib/` and `pubspec.yaml`; let Flutter generate the missing `android/` runner files.

4. Select an Android emulator or connect an Android phone with USB debugging enabled.

## Notes

- All task data is stored locally on the device.
- This version does not require an account, server, API key, or internet connection.
- Reminders are represented in-app; system push notifications are not enabled in this starter version.
- To make a release APK after testing:

  ```bash
  flutter build apk --release
  ```

  The APK is normally written to `build/app/outputs/flutter-apk/app-release.apk`.

## Project layout

```text
lib/
  main.dart
  models/life_task.dart
  services/task_store.dart
  screens/home_screen.dart
  screens/task_editor_screen.dart
  theme/app_theme.dart
```
