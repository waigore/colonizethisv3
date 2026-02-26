import 'package:flutter/material.dart';

/// App themes. Phase 6: pixel-art canon and styling per UXD apply to existing UIs (03a–03m).
/// Asset pipeline: assets/images/; load in Flame/Flutter via rootBundle or Flame cache.
class AppThemes {
  AppThemes._();

  static ThemeData get light => ThemeData.light(useMaterial3: true);

  /// Colonial theme per UXD 02: parchment, colonial brown, dark wood, gold/brass, iron.
  /// Used for main menu mockups and Widgetbook. Uses platform text theme with colonial
  /// colors; Cinzel/Merriweather can be added via bundled fonts or google_fonts when available.
  static ThemeData get colonial {
    const Color parchment = Color(0xFFF5F5DC);
    const Color colonialBrown = Color(0xFF8B4513);
    const Color darkWood = Color(0xFF5D3A1A);
    const Color goldBrass = Color(0xFFC9A227);
    const Color textPrimary = Color(0xFF212121);
    const Color textSecondary = Color(0xFF757575);

    final TextTheme base = ThemeData.light().textTheme;
    final TextTheme textTheme = base.copyWith(
      bodyLarge: base.bodyLarge?.copyWith(color: textPrimary),
      bodyMedium: base.bodyMedium?.copyWith(color: textPrimary),
      bodySmall: base.bodySmall?.copyWith(color: textSecondary),
      headlineMedium: base.headlineMedium?.copyWith(color: textPrimary),
      headlineSmall: base.headlineSmall?.copyWith(color: textPrimary),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: colonialBrown,
        onPrimary: parchment,
        secondary: goldBrass,
        onSecondary: darkWood,
        surface: parchment,
        onSurface: textPrimary,
        error: Colors.brown.shade700,
        onError: parchment,
      ),
      scaffoldBackgroundColor: parchment,
      appBarTheme: AppBarTheme(
        backgroundColor: darkWood,
        foregroundColor: parchment,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: parchment),
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colonialBrown,
          foregroundColor: parchment,
          minimumSize: const Size(88, 48), // 44dp min touch target
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colonialBrown,
          minimumSize: const Size(88, 48),
        ),
      ),
    );
  }
}
