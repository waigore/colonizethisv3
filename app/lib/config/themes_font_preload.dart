import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../package_logger.dart';

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
