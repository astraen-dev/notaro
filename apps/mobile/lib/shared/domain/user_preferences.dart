import "package:freezed_annotation/freezed_annotation.dart";

part "user_preferences.freezed.dart";

part "user_preferences.g.dart";

enum AppThemeMode { light, dark, system }

enum AppFontFamily { sans, serif, mono }

@freezed
abstract class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default(AppThemeMode.system) final AppThemeMode themeMode,
    @Default(250.0) final double accentHue,
    @Default(AppFontFamily.sans) final AppFontFamily fontFamily,
    @Default(50.0) final double anomalyDeviationThreshold,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(final Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}
