import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../package_logger.dart';
import 'editorial_monocle_palette.dart';

part 'themes_colonial.dart';
part 'themes_editorial_monocle.dart';
part 'themes_font_preload.dart';

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

  static ThemeData get colonial => _buildColonialTheme();

  static ThemeData get colonialPixelArt => _buildColonialPixelArtTheme();

  static ThemeData get editorialMonocle => _buildEditorialMonocleTheme();
}
