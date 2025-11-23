import "dart:convert";

import "package:notaro_mobile/core/data/local/shared_prefs.dart";
import "package:notaro_mobile/shared/domain/user_preferences.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

part "preferences_repository.g.dart";

class PreferencesRepository {
  PreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _userPreferencesKey = "user_preferences";

  /// Retrieves [UserPreferences] from local storage.
  /// If no preferences are found, it returns a default configuration.
  UserPreferences getUserPreferences() {
    try {
      final String? jsonString = _prefs.getString(_userPreferencesKey);
      if (jsonString != null) {
        return UserPreferences.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );
      }
      // Return default preferences if nothing is stored yet.
      return const UserPreferences();
    } on FormatException {
      // Handle JSON parsing errors
      return const UserPreferences();
    } on Exception {
      // TODO: Log error
      // Gracefully recover by returning default preferences
      return const UserPreferences();
    }
  }

  /// Saves the provided [UserPreferences] to local storage.
  Future<void> saveUserPreferences(final UserPreferences preferences) async {
    try {
      final String jsonString = jsonEncode(preferences.toJson());
      await _prefs.setString(_userPreferencesKey, jsonString);
    } on Exception {
      // TODO: Log error
      rethrow;
    }
  }
}

@riverpod
Future<PreferencesRepository> preferencesRepository(final Ref ref) async {
  final SharedPreferences prefs = await ref.watch(
    sharedPreferencesProvider.future,
  );
  return PreferencesRepository(prefs);
}
