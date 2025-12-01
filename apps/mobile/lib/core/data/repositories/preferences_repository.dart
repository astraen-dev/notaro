import "package:notaro_mobile/rust/api/native.dart" as rust_api;
import "package:notaro_mobile/shared/domain/user_preferences.dart";

class PreferencesRepository {
  PreferencesRepository();

  Future<UserPreferences> getUserPreferences() async {
    try {
      final rust_api.UserSettings s = await rust_api.getSettings();
      return UserPreferences(
        themeMode: _mapThemeMode(s.themeMode),
        accentHue: s.accentHue.toDouble(),
        fontFamily: _mapFontFamily(s.fontFamily),
      );
    } on Exception catch (_) {
      return const UserPreferences();
    }
  }

  Future<void> saveUserPreferences(final UserPreferences prefs) async {
    final settings = rust_api.UserSettings(
      themeMode: _mapThemeModeToString(prefs.themeMode),
      accentHue: prefs.accentHue.toInt(),
      fontFamily: _mapFontFamilyToString(prefs.fontFamily),
      fontSize: 14,
    );
    await rust_api.updateSettings(settings: settings);
  }

  AppThemeMode _mapThemeMode(final String val) => switch (val) {
    "light" => AppThemeMode.light,
    "dark" => AppThemeMode.dark,
    _ => AppThemeMode.system,
  };

  String _mapThemeModeToString(final AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => "light",
    AppThemeMode.dark => "dark",
    AppThemeMode.system => "system",
  };

  AppFontFamily _mapFontFamily(final String val) => switch (val) {
    "serif" => AppFontFamily.serif,
    "mono" => AppFontFamily.mono,
    _ => AppFontFamily.sans,
  };

  String _mapFontFamilyToString(final AppFontFamily family) => switch (family) {
    AppFontFamily.serif => "serif",
    AppFontFamily.mono => "mono",
    AppFontFamily.sans => "sans",
  };
}
