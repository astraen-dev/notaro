// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    _UserPreferences(
      themeMode:
          $enumDecodeNullable(_$AppThemeModeEnumMap, json['themeMode']) ??
          AppThemeMode.system,
      accentHue: (json['accentHue'] as num?)?.toDouble() ?? 250.0,
      fontFamily:
          $enumDecodeNullable(_$AppFontFamilyEnumMap, json['fontFamily']) ??
          AppFontFamily.sans,
      anomalyDeviationThreshold:
          (json['anomalyDeviationThreshold'] as num?)?.toDouble() ?? 50.0,
    );

Map<String, dynamic> _$UserPreferencesToJson(_UserPreferences instance) =>
    <String, dynamic>{
      'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'accentHue': instance.accentHue,
      'fontFamily': _$AppFontFamilyEnumMap[instance.fontFamily]!,
      'anomalyDeviationThreshold': instance.anomalyDeviationThreshold,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
  AppThemeMode.system: 'system',
};

const _$AppFontFamilyEnumMap = {
  AppFontFamily.sans: 'sans',
  AppFontFamily.serif: 'serif',
  AppFontFamily.mono: 'mono',
};
