import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:google_fonts/google_fonts.dart";
import "package:notaro_mobile/shared/domain/user_preferences.dart";

// ignore_for_file: avoid_redundant_argument_values, unused_field

/// Defines the color palettes, text styles, and component themes for the app.
class AppTheme {
  AppTheme._();

  // --- Tailwind Slate Palette ---
  static const _slate50 = Color(0xFFF8FAFC);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate300 = Color(0xFFCBD5E1);
  static const _slate400 = Color(0xFF94A3B8);
  static const _slate500 = Color(0xFF64748B);
  static const _slate600 = Color(0xFF475569);
  static const _slate700 = Color(0xFF334155);
  static const _slate800 = Color(0xFF1E293B);
  static const _slate900 = Color(0xFF0F172A);

  static const _error = Color(0xFFEF4444);

  /// Generates a Color from a Hue value (0-360) matching Desktop's Tailwind config.
  /// Desktop: hsl(var(--accent-hue), 80%, 60%)
  static Color _colorFromHue(final double hue) =>
      HSLColor.fromAHSL(1, hue, 0.80, 0.60).toColor();

  static ColorScheme _lightColorScheme(final double accentHue) {
    final Color primary = _colorFromHue(accentHue);
    return ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: primary,
      onSecondary: Colors.white,
      tertiary: _slate500,
      error: _error,
      surface: _slate50.withValues(alpha: 0.5),
      // Transparent for glass
      onSurface: _slate700,
      onSurfaceVariant: _slate500,
      outline: _slate200,
      outlineVariant: _slate100,
      shadow: Colors.black.withValues(alpha: 0.1),
    );
  }

  static ColorScheme _darkColorScheme(final double accentHue) {
    final Color primary = _colorFromHue(accentHue);
    return ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      secondary: primary,
      onSecondary: Colors.white,
      tertiary: _slate400,
      error: _error,
      surface: _slate900.withValues(alpha: 0.5),
      // Transparent for glass
      onSurface: _slate200,
      onSurfaceVariant: _slate400,
      outline: _slate700,
      outlineVariant: _slate800,
      shadow: Colors.black.withValues(alpha: 0.3),
    );
  }

  // --- Typography ---
  static TextTheme _buildTextTheme(
    final ColorScheme colorScheme,
    final AppFontFamily fontFamily,
  ) {
    final baseTextStyle = TextStyle(color: colorScheme.onSurface);

    final base = TextTheme(
      displayLarge: baseTextStyle.copyWith(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: baseTextStyle.copyWith(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: baseTextStyle.copyWith(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleMedium: baseTextStyle.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextStyle.copyWith(fontSize: 16.sp, height: 1.6),
      bodyMedium: baseTextStyle.copyWith(fontSize: 14.sp, height: 1.5),
      labelSmall: baseTextStyle.copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );

    // Dynamic Font Mapping matching Desktop
    switch (fontFamily) {
      case AppFontFamily.sans:
        return GoogleFonts.interTextTheme(base);
      case AppFontFamily.serif:
        return GoogleFonts.merriweatherTextTheme(base);
      case AppFontFamily.mono:
        return GoogleFonts.jetBrainsMonoTextTheme(base);
    }
  }

  static ThemeData light(
    final BuildContext context,
    final double accentHue,
    final AppFontFamily fontFamily,
  ) => _buildThemeData(_lightColorScheme(accentHue), _slate50, fontFamily);

  static ThemeData dark(
    final BuildContext context,
    final double accentHue,
    final AppFontFamily fontFamily,
  ) => _buildThemeData(_darkColorScheme(accentHue), _slate900, fontFamily);

  static ThemeData _buildThemeData(
    final ColorScheme colorScheme,
    final Color scaffoldBg,
    final AppFontFamily fontFamily,
  ) {
    final TextTheme textTheme = _buildTextTheme(colorScheme, fontFamily);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontFamily: textTheme.bodyMedium?.fontFamily,
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 20.sp,
      ),
      // Ensure Slider uses the accent color
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
        overlayColor: colorScheme.primary.withValues(alpha: 0.1),
      ),
    );
  }
}
