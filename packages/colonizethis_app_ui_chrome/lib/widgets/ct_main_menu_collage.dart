import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

part 'ct_main_menu_collage_painter.dart';
part 'ct_main_menu_collage_painter_navigation.dart';
part 'ct_main_menu_collage_painter_instruments.dart';
part 'ct_main_menu_collage_painter_maritime.dart';

/// Decorative dark SVG-collage background for the editorial-monocle main
/// menu (`SHEL10002`).
///
/// Implements `Refs #2860` S2 + `SPEC/ui/main-menu.md` § *Background*. The
/// widget is a self-painted decorative collage (no asset) used as the
/// fixed-position background of the `pixelArt` variant of `CtMainMenu`.
/// All primitives are painted via Flutter `CustomPainter`; **no external
/// SVG runtime asset is required**.
///
/// The painter mirrors the inline `<svg class="collage-svg">` block of
/// `SPEC/ui/mockups/SHEL10002-main-menu.html` (viewBox `1920 x 1080`,
/// `preserveAspectRatio="xMidYMid meet"`). Glyphs scale uniformly to fit
/// the smaller of the two parent dimensions and are centered with
/// pillarbox/letterbox margins so the collage never stretches.
///
/// All colors resolve from [EditorialMonoclePalette] tokens (issue #2858):
///
/// * `--accent` is the `currentColor` for every SVG primitive (set on the
///   `.collage-svg` root in the mockup).
/// * `--bg` is the canvas background that the collage sits over (painted
///   by the parent `Scaffold`).
///
/// Glyph families (mockup `<svg>` order):
///
/// 1. Dashed trade-route arcs (5 quadratic curves at `0.40` group alpha).
/// 2. Navigation-star waypoints (4 diamond + ring pairs at `0.45`).
/// 3. Telescope (top-left, rotated `-14°`, `0.55`).
/// 4. Spyglass (top-left smaller, rotated `-6°`, `0.50`).
/// 5. Crossed muskets (top-right, rotated `+32°` and `-36°`, `0.55`).
/// 6. Powder horn (top-right, rotated `-40°`, `0.50`).
/// 7. Sextant (mid-left, `0.55`).
/// 8. Hourglass (mid-left lower, `0.55`).
/// 9. Anchor (bottom-left, `0.55`).
/// 10. Soldier silhouette (mid-right, `0.55`).
/// 11. Ship's wheel (mid-right, `0.55`).
/// 12. Cannon with cannonballs (bottom-right, `0.55`).
/// 13. Layered wave bands (bottom, `0.50`).
///
/// A final group opacity of [_collageOpacity] (`0.8` per the
/// `.collage-svg { opacity }` rule) is layered over every primitive so the
/// collage reads as a muted background, not a foreground illustration.
class CtMainMenuCollage extends StatelessWidget {
  const CtMainMenuCollage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _CtMainMenuCollagePainter(
          glyphColor: EditorialMonoclePalette.accent,
        ),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

/// Internal helper exposed for tests: returns the canonical SVG viewBox the
/// painter scales its glyphs from (`1920 x 1080`).
@visibleForTesting
Size get ctMainMenuCollageViewBoxForTesting => const Size(
  _CtMainMenuCollagePainter._viewBoxWidth,
  _CtMainMenuCollagePainter._viewBoxHeight,
);

/// Internal helper exposed for tests: returns the documented final group
/// alpha applied to every collage primitive (`.collage-svg { opacity }`).
@visibleForTesting
double get ctMainMenuCollageOpacityForTesting =>
    _CtMainMenuCollagePainter._collageOpacity;

/// Internal helper exposed for tests: returns the per-group opacity
/// multiplier for a given glyph family. Tests use this to pin the values
/// against the mockup `<g opacity>` attributes without parsing SVG.
@visibleForTesting
Map<String, double> ctMainMenuCollageGroupOpacitiesForTesting() => const {
  'tradeRoutes': _CtMainMenuCollagePainter._tradeRoutesOpacity,
  'waypoints': _CtMainMenuCollagePainter._waypointsOpacity,
  'telescope': _CtMainMenuCollagePainter._telescopeOpacity,
  'spyglass': _CtMainMenuCollagePainter._spyglassOpacity,
  'muskets': _CtMainMenuCollagePainter._musketsOpacity,
  'powderHorn': _CtMainMenuCollagePainter._powderHornOpacity,
  'sextant': _CtMainMenuCollagePainter._sextantOpacity,
  'hourglass': _CtMainMenuCollagePainter._hourglassOpacity,
  'anchor': _CtMainMenuCollagePainter._anchorOpacity,
  'soldier': _CtMainMenuCollagePainter._soldierOpacity,
  'shipsWheel': _CtMainMenuCollagePainter._shipsWheelOpacity,
  'cannon': _CtMainMenuCollagePainter._cannonOpacity,
  'waves': _CtMainMenuCollagePainter._wavesOpacity,
};
