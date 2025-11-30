import "package:flutter/material.dart";
import "package:notaro_mobile/core/application/preferences_provider.dart";
import "package:notaro_mobile/shared/domain/user_preferences.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "theme_provider.g.dart";

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    // Listen to persisted preferences to hydrate initial state
    final UserPreferences? prefs = ref.watch(userPreferencesProvider).value;
    if (prefs == null) {
      return ThemeMode.system;
    }

    return switch (prefs.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(final ThemeMode mode) async {
    state = mode;

    // Map Flutter ThemeMode back to Domain AppThemeMode for persistence
    final AppThemeMode appMode = switch (mode) {
      ThemeMode.light => AppThemeMode.light,
      ThemeMode.dark => AppThemeMode.dark,
      ThemeMode.system => AppThemeMode.system,
    };

    await ref.read(userPreferencesProvider.notifier).setThemeMode(appMode);
  }
}
