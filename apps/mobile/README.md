# Notaro Mobile

This is the mobile application for Notaro, targeting iOS and Android.

## Technology Stack

- **Framework:** Flutter
- **Language:** Dart
- **Rust Integration:** `flutter_rust_bridge`

## Architectural Role

The Flutter app provides the native mobile UI. To interact with the database and business logic, it does not
re-implement it in Dart. Instead, it uses a Foreign Function Interface (FFI) bridge to call functions directly in the
`notaro_core` Rust crate. This ensures logic is perfectly consistent with the desktop and server applications.

## Getting Started (from this directory)

1. **Ensure you have the Flutter SDK installed.**
2. **Get Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the App on a Connected Device/Emulator:**
   ```bash
   flutter run
   ```
4. **Build the App:**
   - **Android:** `flutter build apk` or `flutter build appbundle`
   - **iOS:** `flutter build ipa`

## Project Structure

The codebase follows a **feature-first** architecture and uses separate entry points for different
build environments (flavors).

```
lib/
├── core/
│   ├── data/         # Shared data sources
│   ├── navigation/   # GoRouter configuration and routes
│   ├── ui/           # App-wide UI (themes, navigation shell)
│   └── utils/        # Shared utilities and extensions
│
├── features/
│   ├── [feature_name]/
│   │   ├── application/  # Business logic & Riverpod providers
│   │   ├── data/         # Feature-specific repositories
│   │   ├── domain/       # Models and entities (often with Freezed)
│   │   └── presentation/ # UI (screens, widgets)
│   └── ...
│
├── shared/
│   ├── domain/       # Domain models shared across multiple features
│   └── widgets/      # Reusable widgets (buttons, dialogs, etc.)
│
├── main.dart  # Entry point
```

## License

This package is licensed under the MIT License. See the [LICENSE](../../LICENSE) file in the root of the repository for the full text.
