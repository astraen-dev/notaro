import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

// ignore_for_file: avoid_redundant_argument_values

/// Defines the color palettes, text styles, and component themes for the app.
class AppTheme {
  AppTheme._();

  // --- Color Definitions (Notaro Palettes) ---
  static const _primary = Color(0xFF5E35B1); // Deep Purple Seed
  static const _primaryDark = Color(0xFFD1C4E9);
  static const _onPrimaryDark = Color(0xFF311B92);
  static const _secondary = Color(0xFF7E57C2);
  static const _secondaryDark = Color(0xFF9575CD);
  static const _tertiary = Color(0xFF00897B); // Teal accent
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

  // --- Base TextTheme with Font sizes and weights ---
  static TextTheme get _baseTextTheme => const TextTheme(
    displayLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 64),
    displayMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 44),
    displaySmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 36),
    headlineLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 32),
    headlineMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 28),
    headlineSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12),
    labelLarge: TextStyle(fontSize: 16),
    labelMedium: TextStyle(fontSize: 14),
    labelSmall: TextStyle(fontSize: 12),
  );

  // --- Merged & Colored TextThemes ---
  static TextTheme _buildTextTheme(
    final TextTheme base,
    final ColorScheme colorScheme,
  ) {
    // Merges Readex Pro for headlines and Inter for body/label text
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
  static ThemeData get light => _buildThemeData(_lightColorScheme);

  static ThemeData get dark => _buildThemeData(_darkColorScheme);

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
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.tertiary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.transparent, width: 0),
        ),
        color: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      ),
    );
  }
}
