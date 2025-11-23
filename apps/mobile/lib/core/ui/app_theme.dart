import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:google_fonts/google_fonts.dart";

// ignore_for_file: avoid_redundant_argument_values

/// Defines the color palettes, text styles, and component themes for the app.
class AppTheme {
  AppTheme._();

  // --- Color Definitions (Notaro Palettes) ---
  static const _primary = Color(0xFF5E35B1);
  static const _primaryDark = Color(0xFFD1C4E9);
  static const _onPrimaryDark = Color(0xFF311B92);
  static const _secondary = Color(0xFF7E57C2);
  static const _secondaryDark = Color(0xFF9575CD);
  static const _tertiary = Color(0xFF00897B);
  static const _error = Color(0xFFBA1A1A);
  static const _errorDark = Color(0xFFFF897D);
  static const _onErrorDark = Color(0xFF410002);

  // --- Light Mode ColorScheme ---
  static final _lightColorScheme = ColorScheme.fromSeed(
    seedColor: _primary,
    primary: _primary,
    onPrimary: Colors.white,
    secondary: _secondary,
    onSecondary: Colors.white,
    tertiary: _tertiary,
    onTertiary: Colors.white,
    error: _error,
    onError: Colors.white,
    brightness: Brightness.light,
    surface: const Color(0xFFF8FAFC),
    onSurface: const Color(0xFF171B1E),
    surfaceContainer: const Color(0xFFFFFFFF),
    surfaceContainerHighest: const Color(0xFFE0E3E7),
    onSurfaceVariant: const Color(0xFF536168),
    outline: const Color(0xFFC4C7C5),
    outlineVariant: const Color(0xFFEEF0F2),
    shadow: const Color(0xFF000000),
  );

  // --- Dark Mode ColorScheme ---
  static final _darkColorScheme = ColorScheme.fromSeed(
    seedColor: _primary,
    primary: _primaryDark,
    onPrimary: _onPrimaryDark,
    secondary: _secondaryDark,
    onSecondary: Colors.white,
    tertiary: _tertiary,
    onTertiary: Colors.white,
    error: _errorDark,
    onError: _onErrorDark,
    brightness: Brightness.dark,
    surface: const Color(0xFF101416),
    onSurface: const Color(0xFFE8E8E8),
    surfaceContainer: const Color(0xFF1C2226),
    surfaceContainerHighest: const Color(0xFF2C3238),
    onSurfaceVariant: const Color(0xFFA8B4BC),
    outline: const Color(0xFF40484D),
    outlineVariant: const Color(0xFF282E32),
    shadow: const Color(0xFF000000),
  );

  // --- Base TextTheme with Responsive Font sizes ---
  static TextTheme get _baseTextTheme => TextTheme(
    displayLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 64.sp),
    displayMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 44.sp),
    displaySmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 36.sp),
    headlineLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 32.sp),
    headlineMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 28.sp),
    headlineSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 24.sp),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20.sp),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp),
    titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
    bodyLarge: TextStyle(fontSize: 16.sp),
    bodyMedium: TextStyle(fontSize: 14.sp),
    bodySmall: TextStyle(fontSize: 12.sp),
    labelLarge: TextStyle(fontSize: 16.sp),
    labelMedium: TextStyle(fontSize: 14.sp),
    labelSmall: TextStyle(fontSize: 12.sp),
  );

  static TextTheme _buildTextTheme(
    final TextTheme base,
    final ColorScheme colorScheme,
  ) {
    final TextTheme readexTheme = GoogleFonts.readexProTextTheme(base);
    final TextTheme interTheme = GoogleFonts.interTextTheme(base);
    return readexTheme
        .copyWith(
          bodyLarge: interTheme.bodyLarge,
          bodyMedium: interTheme.bodyMedium,
          bodySmall: interTheme.bodySmall,
          labelLarge: interTheme.labelLarge,
          labelMedium: interTheme.labelMedium,
          labelSmall: interTheme.labelSmall,
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );
  }

  // --- Main ThemeData Definitions ---
  // Now functions to ensure Context/ScreenUtil is ready
  static ThemeData light(final BuildContext context) =>
      _buildThemeData(_lightColorScheme);
  static ThemeData dark(final BuildContext context) =>
      _buildThemeData(_darkColorScheme);

  static ThemeData _buildThemeData(final ColorScheme colorScheme) {
    final TextTheme textTheme = _buildTextTheme(_baseTextTheme, colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24.sp),
        actionsIconTheme: IconThemeData(
          color: colorScheme.tertiary,
          size: 24.sp,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: EdgeInsets.all(16.w),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(12.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(12.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 2.w),
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Colors.transparent, width: 0),
        ),
        color: colorScheme.surfaceContainer,
      ),
    );
  }
}
