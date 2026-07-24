import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'themes_font_preload.dart';

/// Editorial-monocle dark theme: SPEC/ui/pixel-art-ui-catalog.md
/// § Editorial-monocle palette. Tokens resolve via
/// [EditorialMonoclePalette]; display text uses the Cinzel font family
/// (bundled under `app/google_fonts/` and registered at startup by
/// [preloadEditorialMonocleFonts]), body text uses Flutter's platform
/// sans-serif default so it follows the system-ui / -apple-system fallback
/// chain on each OS.
///
/// The theme intentionally constructs Cinzel-styled TextStyles with
/// `fontFamily: editorialMonocleDisplayFontFamily` directly rather than
/// calling `GoogleFonts.cinzel(...)` at construction time. That keeps
/// the theme constructor synchronous and hermetic (unit tests can read
/// the theme without triggering Google Fonts registration). The bundled
/// font bytes are verified and registered once at app startup via
/// [preloadEditorialMonocleFonts]; production bootstrap awaits that call
/// and hard-errors when bundled Cinzel cannot be loaded.
ThemeData buildEditorialMonocleTheme() {
  final Color bg = EditorialMonoclePalette.bg;
  final Color surface = EditorialMonoclePalette.surface;
  final Color surfaceLite = EditorialMonoclePalette.surfaceLite;
  final Color fg = EditorialMonoclePalette.fg;
  final Color muted = EditorialMonoclePalette.muted;
  final Color border = EditorialMonoclePalette.border;
  final Color accent = EditorialMonoclePalette.accent;
  final Color accentDim = EditorialMonoclePalette.accentDim;
  final Color danger = EditorialMonoclePalette.danger;

  final TextTheme base = ThemeData.dark(useMaterial3: true).textTheme;
  TextStyle? cinzel(TextStyle? source) =>
      source?.copyWith(color: fg, fontFamily: editorialMonocleDisplayFontFamily);
  final TextTheme textTheme = base
      .apply(bodyColor: fg, displayColor: fg)
      .copyWith(
        headlineMedium: cinzel(base.headlineMedium),
        headlineSmall: cinzel(base.headlineSmall),
        titleLarge: cinzel(base.titleLarge),
        titleMedium: cinzel(base.titleMedium),
        titleSmall: cinzel(base.titleSmall),
        bodyLarge: base.bodyLarge?.copyWith(color: fg),
        bodyMedium: base.bodyMedium?.copyWith(color: fg),
        bodySmall: base.bodySmall?.copyWith(color: muted),
        labelLarge: base.labelLarge?.copyWith(color: fg),
        labelMedium: base.labelMedium?.copyWith(color: muted),
        labelSmall: base.labelSmall?.copyWith(color: muted),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: accent,
      onPrimary: bg,
      secondary: accentDim,
      onSecondary: bg,
      surface: surface,
      onSurface: fg,
      surfaceContainerHighest: surfaceLite,
      outline: border,
      error: danger,
      onError: bg,
    ),
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceLite,
      foregroundColor: fg,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: fg),
    ),
    dividerColor: border,
    textTheme: textTheme,
  );
}
