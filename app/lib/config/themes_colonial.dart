import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color darkWood = Color(0xFF5D3A1A);

/// Colonial theme per UXD 02: parchment, colonial brown, dark wood, gold/brass, iron.
/// Used for main menu mockups and Widgetbook. Uses platform text theme with colonial
/// colors.
ThemeData buildColonialTheme() {
  const Color parchment = Color(0xFFF5F5DC);
  const Color colonialBrown = Color(0xFF8B4513);
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

/// Colonial theme with serif font (Cinzel) for pixel-art main menu. SPEC/ui/main-menu.md.
/// Pixel font to be defined later; serif keeps basic colonial theme.
ThemeData buildColonialPixelArtTheme() {
  final ThemeData base = buildColonialTheme();
  final TextTheme baseText = base.textTheme;
  return base.copyWith(
    textTheme: baseText.copyWith(
      headlineMedium: GoogleFonts.cinzel(textStyle: baseText.headlineMedium),
      headlineSmall: GoogleFonts.cinzel(textStyle: baseText.headlineSmall),
      titleLarge: GoogleFonts.cinzel(textStyle: baseText.titleLarge),
      titleMedium: GoogleFonts.cinzel(textStyle: baseText.titleMedium),
      titleSmall: GoogleFonts.cinzel(textStyle: baseText.titleSmall),
      bodyLarge: GoogleFonts.cinzel(textStyle: baseText.bodyLarge),
      bodyMedium: GoogleFonts.cinzel(textStyle: baseText.bodyMedium),
      bodySmall: GoogleFonts.cinzel(textStyle: baseText.bodySmall),
    ),
  );
}
