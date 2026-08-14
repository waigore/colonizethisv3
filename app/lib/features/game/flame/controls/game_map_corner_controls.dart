import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags, MapMarksCombination;

import '../../../../config/app_assets.dart';
import '../../screens/game/game_screen_shared.dart';

import 'game_map_corner_controls_button.dart';

/// Bottom-left horizontal row of map tool buttons for the in-game map.
///
/// SPEC: `SPEC/ui/empire-overview.md` § Base layer display cycle,
/// Home-to-capital, Map display options, and § Corner controls chrome
/// (dark editorial-monocle). Implements `Refs #2861` R5 / S4: each
/// corner button paints the canonical 32 × 32 dp dark editorial-monocle
/// chrome (`CtGradients.railButtonGradient` surface + 1 px `--border`
/// outline with hover/pressed accent-dim shift) so the row reads as
/// dark map chrome rather than the legacy white Material overlay.
///
/// Narrow layout (issue #2870 S3, `MediaQuery.size.width < kNarrowBreakpoint`):
/// host constructs with `narrow: true`. Corner buttons compress to 24 × 24 dp
/// and the horizontal gap tightens from 3 dp to 2 dp per
/// `SPEC/ui/empire-overview.md` § Narrow corner-control measurements.
class GameMapCornerControls extends StatelessWidget {
  const GameMapCornerControls({
    required this.onCycleBaseLayerDisplayMode,
    required this.onCenterOnHomeCapital,
    required this.onOpenMapDisplayOptions,
    this.homeToCapitalEnabled = true,
    this.narrow = false,
    this.mapBaseLayerFlags = MapBaseLayerFlags.fullDetail,
    super.key,
  });

  final VoidCallback onCycleBaseLayerDisplayMode;
  final VoidCallback onCenterOnHomeCapital;
  final VoidCallback onOpenMapDisplayOptions;
  final bool homeToCapitalEnabled;

  /// Current information-layer flags; drives the cycle-button tooltip (Refs #4388).
  final MapBaseLayerFlags mapBaseLayerFlags;

  /// When true, render the row at narrow-viewport measurements per
  /// `SPEC/ui/mobile-adaptation.md` § In-game shell (issue #2870 S3).
  final bool narrow;

  /// Side length of each corner control button. Matches mockup
  /// `.corner-btn` 32 × 32 px (`SPEC/ui/mockups/GAME10001-game-screen.html`).
  /// The narrow-layout 24 × 24 measurement is governed by
  /// `SPEC/ui/mobile-adaptation.md` / issue #2870.
  static const double buttonSize = 32;

  /// Side length of the icon glyph centered inside the button. Matches
  /// mockup `.corner-btn img` 22 × 22 px.
  static const double iconSize = 22;

  /// Horizontal gap between adjacent corner buttons. Matches mockup
  /// `.corner-controls` `gap: 3px`.
  static const double rowGap = 3;

  /// Side length of each corner control button under narrow layout
  /// (mockup `.corner-btn @media (max-width:600px) { width:24px; height:24px }`;
  /// authority: `SPEC/ui/mobile-adaptation.md` § In-game shell).
  static const double narrowButtonSize = 24;

  /// Horizontal gap between adjacent corner buttons under narrow layout
  /// (tightened from 3 dp to match the compressed
  /// `.corner-controls @media (max-width:600px) { left:2px; bottom:2px }`
  /// chrome; authority: `SPEC/ui/empire-overview.md` § Narrow corner-control
  /// measurements).
  static const double narrowRowGap = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final gapWidth = narrow ? narrowRowGap : rowGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapCornerIconButton(
          buttonKey: kBaseLayerCycleButtonKey,
          tooltip: mapMarksTooltip(l10n, mapBaseLayerFlags),
          onTap: onCycleBaseLayerDisplayMode,
          assetPath: '${kAppIconAssetPrefix}ui_icon_layer_toggle.png',
          narrow: narrow,
        ),
        SizedBox(width: gapWidth),
        MapCornerIconButton(
          buttonKey: kHomeToCapitalButtonKey,
          tooltip: l10n.mapCorner_tooltipCenterCapital,
          onTap: homeToCapitalEnabled ? onCenterOnHomeCapital : null,
          assetPath: '${kAppIconAssetPrefix}ui_icon_home_capital.png',
          narrow: narrow,
        ),
        SizedBox(width: gapWidth),
        MapCornerIconButton(
          buttonKey: kMapDisplayOptionsButtonKey,
          tooltip: l10n.mapCorner_tooltipMapDisplayOptions,
          onTap: onOpenMapDisplayOptions,
          assetPath: '${kAppIconAssetPrefix}ui_icon_map_options.png',
          narrow: narrow,
        ),
      ],
    );
  }
}

String mapMarksTooltip(AppLocalizations l10n, MapBaseLayerFlags flags) {
  final combination = switch (flags.combination) {
    MapMarksCombination.terrainOnly => l10n.mapCorner_mapMarks_terrainOnly,
    MapMarksCombination.resources => l10n.mapCorner_mapMarks_resources,
    MapMarksCombination.resourcesAndImprovements =>
      l10n.mapCorner_mapMarks_resourcesAndImprovements,
    MapMarksCombination.fullDetail => l10n.mapCorner_mapMarks_full,
    MapMarksCombination.improvements => l10n.mapCorner_mapMarks_improvements,
    MapMarksCombination.improvementsAndRoads =>
      l10n.mapCorner_mapMarks_improvementsAndRoads,
  };
  return l10n.mapCorner_tooltipMapMarks(combination);
}
