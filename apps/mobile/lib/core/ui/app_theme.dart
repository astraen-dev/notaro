import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:google_fonts/google_fonts.dart";

// ignore_for_file: avoid_redundant_argument_values, unused_field

/// Defines the color palettes, text styles, and component themes for the app.
class AppTheme {
  AppTheme._();

  // --- Tailwind Slate Palette ---
  static const _slate50 = Color(0xFFF8FAFC);
  static const _slate100 = Color(0xFFF1F5F9); // Light Mode BG Base
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate300 = Color(0xFFCBD5E1);
  static const _slate400 = Color(0xFF94A3B8);
  static const _slate500 = Color(0xFF64748B);
  static const _slate600 = Color(0xFF475569);
  static const _slate700 = Color(0xFF334155);
  static const _slate800 = Color(0xFF1E293B);
  static const _slate900 = Color(0xFF0F172A); // Dark Mode BG Base

  // --- Tailwind Indigo Palette (Accent) ---
  static const _indigo50 = Color(0xFFEEF2FF);
  static const _indigo100 = Color(0xFFE0E7FF);
  static const _indigo500 = Color(0xFF6366F1); // Primary
  static const _indigo600 = Color(0xFF4F46E5);
  static const _indigo700 = Color(0xFF4338CA);

  // --- Functional Colors ---
  static const _error = Color(0xFFEF4444); // Red-500

  // --- Light Mode ColorScheme ---
  static final _lightColorScheme = ColorScheme.light(
    primary: _indigo500,
    onPrimary: Colors.white,
    secondary: _indigo500,
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

  // --- Dark Mode ColorScheme ---
  static final _darkColorScheme = ColorScheme.dark(
    primary: _indigo500,
    onPrimary: Colors.white,
    secondary: _indigo500,
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

  // --- Typography (Inter Only) ---
  static TextTheme _buildTextTheme(final ColorScheme colorScheme) {
    // Base sizes tailored to match Desktop's utility classes approx.
    final base = TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16.sp, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14.sp, height: 1.5),
      labelSmall: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );

    return GoogleFonts.interTextTheme(base).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }

  static ThemeData light(final BuildContext context) =>
      _buildThemeData(_lightColorScheme, _slate50);

  static ThemeData dark(final BuildContext context) =>
      _buildThemeData(_darkColorScheme, _slate900);

  static ThemeData _buildThemeData(
    final ColorScheme colorScheme,
    final Color scaffoldBg,
  ) {
    final TextTheme textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      // Important for mesh bg
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
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 20.sp,
      ),
    );
  }
}
