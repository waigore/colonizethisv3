// Main-menu pixel-art logo region. Refs #3878; Refs #4117 de-part.

import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_compass_rose.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_fleur_de_lis_ornament.dart';

import '../config/themes.dart';

/// Dark editorial-monocle logo region for the `pixelArt` main-menu variant.
///
/// Renders, top-to-bottom: the eyebrow tagline (small-caps `--muted`), the
/// [CtCompassRose] emblem, and a title row composed of
/// `[CtFleurDeLisOrnament] — title text — [CtFleurDeLisOrnament]`. Mirrors
/// `SPEC/ui/main-menu.md` § Logo region.
class MainMenuPixelArtLogoRegion extends StatelessWidget {
  const MainMenuPixelArtLogoRegion({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? eyebrowStyle = theme.textTheme.labelSmall?.copyWith(
      color: EditorialMonoclePalette.muted,
      letterSpacing: 2.5,
      fontFamily: editorialMonocleDisplayFontFamily,
    );
    final TextStyle? titleStyle = theme.textTheme.headlineMedium?.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: 0.08,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.mainMenu_eyebrow.toUpperCase(),
          textAlign: TextAlign.center,
          style: eyebrowStyle,
        ),
        const SizedBox(height: 16),
        const CtCompassRose(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CtFleurDeLisOrnament(),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: titleStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const CtFleurDeLisOrnament(),
          ],
        ),
      ],
    );
  }
}
