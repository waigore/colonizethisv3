import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../package_logger.dart';
import 'editorial_monocle_palette.dart';

const Color darkWood = Color(0xFF5D3A1A);

/// App themes. Phase 6: pixel-art canon and styling per UXD apply to existing UIs (03a–03m).
/// Asset pipeline: `assets/images/` (terrain, nine-patch, main menu art); `assets/icons/` (`ui_icon_*.png`); load via rootBundle or Flame cache.
///
/// Default visual mode for the running app is [editorialMonocle] — see
/// `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette. The
/// legacy [colonial] / [colonialPixelArt] themes are preserved for
/// Widgetbook fallback and debug toggles only.
class AppThemes {
  AppThemes._();

  static ThemeData get light => ThemeData.light(useMaterial3: true);

  /// Colonial theme per UXD 02: parchment, colonial brown, dark wood, gold/brass, iron.
  /// Used for main menu mockups and Widgetbook. Uses platform text theme with colonial
  /// colors.
  static ThemeData get colonial {
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
  static ThemeData get colonialPixelArt {
    final ThemeData base = colonial;
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
  static ThemeData get editorialMonocle {
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
}

/// Font family applied to display / heading text styles in
/// [AppThemes.editorialMonocle]. Matches the bundled Cinzel family name.
const String editorialMonocleDisplayFontFamily = 'Cinzel';

/// Display weights used across editorial-monocle UI (w500–w700 on headings).
const List<FontWeight> _editorialMonocleCinzelWeights = <FontWeight>[
  FontWeight.w400,
  FontWeight.w500,
  FontWeight.w600,
  FontWeight.w700,
];

final _fontLog = packageLogger('font');

/// Registers bundled Cinzel display weights and awaits completion.
///
/// Call once from app startup before `runApp`. In tests and e2e, pass
/// [skipInTests] = true (or inject a no-op via `bootstrapApp.preloadFonts`)
/// so the suite stays hermetic.
///
/// On failure the error is logged and rethrown so production bootstrap
/// hard-errors instead of silently falling back to a platform serif.
Future<void> preloadEditorialMonocleFonts({bool skipInTests = false}) async {
  if (skipInTests) return;
  try {
    await GoogleFonts.pendingFonts(
      _editorialMonocleCinzelWeights
          .map((FontWeight weight) => GoogleFonts.cinzel(fontWeight: weight))
          .toList(),
    );
  } catch (e, st) {
    _fontLog.e(
      'bundled Cinzel display font failed to load',
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
}
