/// Tile-section label helpers and row builders for [ProvinceSeaZoneDetailOverlay].

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'province_sea_zone_detail_overlay.dart';

/// Supplementary GDD label for [roadLevel] on land tiles (issue #1537 / extraction-and-improvements § Transport Level).
@visibleForTesting
String roadRailSupplementaryLabel(AppLocalizations l10n, int roadLevel) {
  return switch (roadLevel) {
    0 => l10n.provinceOverlay_tileRoadLabelNone,
    1 => l10n.provinceOverlay_tileRoadLabelPrimitiveRoad,
    2 => l10n.provinceOverlay_tileRoadLabelImprovedRoad,
    4 => l10n.provinceOverlay_tileRoadLabelPortOrRailroad,
    _ => l10n.provinceOverlay_tileRoadLabelNonStandard,
  };
}

/// Primary Tile-section line for land tiles; [transportLevel] is stored road/rail level.
@visibleForTesting
String roadRailTransportLevelPrimaryLine(
  AppLocalizations l10n,
  int transportLevel,
) {
  return l10n.provinceOverlay_tileRoadTransportLevel(transportLevel);
}

/// Ordered text lines for Tile “Road / railroad” (null → sea / no land transport row).
@visibleForTesting
List<String> roadRailTileDetailLinesForTests({
  required AppLocalizations l10n,
  required int? transportLevel,
}) {
  if (transportLevel == null) {
    return [l10n.provinceOverlay_tileRoadNone];
  }
  final v = transportLevel;
  final lines = <String>[
    roadRailTransportLevelPrimaryLine(l10n, v),
    roadRailSupplementaryLabel(l10n, v),
  ];
  if (v == 1) {
    lines.add(l10n.provinceOverlay_tileRoadRailGloss);
  }
  return lines;
}

/// Parses `regionId|…|x|y` tile keys for the province overlay; null when invalid.
@visibleForTesting
({int x, int y})? tryParseProvinceOverlayTileCoords({
  required String regionId,
  required int regionWidth,
  required int regionHeight,
  required String selectedTileKey,
}) {
  // Defensive parse: last two `|`-separated segments are x|y. Some legacy
  // overlay call sites construct 5-part keys where the local id itself
  // contains a `|`; preserve compatibility while still avoiding the
  // List<String> allocation from `split('|')`.
  final firstPipe = selectedTileKey.indexOf('|');
  if (firstPipe <= 0) return null;
  final keyRegion = selectedTileKey.substring(0, firstPipe);
  if (keyRegion != regionId) return null;
  final lastPipe = selectedTileKey.lastIndexOf('|');
  if (lastPipe <= firstPipe || lastPipe + 1 >= selectedTileKey.length) {
    return null;
  }
  final secondLastPipe = selectedTileKey.lastIndexOf('|', lastPipe - 1);
  if (secondLastPipe <= firstPipe) return null;
  final x = int.tryParse(
    selectedTileKey.substring(secondLastPipe + 1, lastPipe),
  );
  final y = int.tryParse(selectedTileKey.substring(lastPipe + 1));
  if (x == null || y == null) {
    return null;
  }
  if (x < 0 || x >= regionWidth || y < 0 || y >= regionHeight) {
    return null;
  }
  return (x: x, y: y);
}

@visibleForTesting
String tileDetailProspectedDisplayLabel(
  AppLocalizations l10n, {
  required bool terrainProspectable,
  required bool playerHasProspected,
}) {
  if (!terrainProspectable) return '—';
  return playerHasProspected
      ? l10n.provinceOverlay_tileProspectedYes
      : l10n.provinceOverlay_tileProspectedNo;
}

Widget _buildTileResourceLabelRow({
  required BuildContext context,
  required AppLocalizations l10n,
  required String? resourceVisible,
  required String resourceLabel,
}) {
  // Dark-theme tokens (Refs #2865, SPEC § Dark-theme Tile section body
  // tokens — live-data body rows). Pin the Resource row prefix, the
  // visible-commodity label rendered by `ResourceLabelInline`, and the
  // no-resource fallback Text to EditorialMonoclePalette.fg via the
  // shared `_fgBodyStyle()` helper so the editorial-monocle dark theme
  // owns these live-data rows alongside coordinates / terrain /
  // civilian-units / Prospected / Improvement / road primary / sea-tile
  // no-road. `ResourceLabelInline.labelStyle` is the new opt-in pin
  // path so the Tile call site can fix the commodity-id label colour
  // without changing the default fall-through used by the Economic
  // section row layout (which keeps its existing token contract).
  final bodyStyle = _fgBodyStyle();
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(l10n.provinceOverlay_tileResourcePrefix, style: bodyStyle),
      if (resourceVisible != null)
        ResourceLabelInline(
          commodityId: resourceVisible,
          labelStyle: bodyStyle,
        )
      else
        Text(resourceLabel, style: bodyStyle),
    ],
  );
}

Widget _buildTileImprovementLabel({
  required AppLocalizations l10n,
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  final improvementLine = _improvementLabelForTileDetail(
    l10n: l10n,
    impLevel: impLevel,
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return Text(
    l10n.provinceOverlay_tileImprovement(improvementLine),
    style: _fgBodyStyle(),
  );
}

/// Disabled-state opacity for the Tile section inline shortcut icons
/// (`Explore`, `Prospect`, `Build improvement`). Pinned at `0.65` so the
/// SPEC § Style / implementation — Dark-theme Tile section body tokens
/// contract resolves the disabled color deterministically from
/// [EditorialMonoclePalette.muted].
@visibleForTesting
const double kProvinceOverlayTileInlineActionDisabledAlpha = 0.65;

List<Widget> _buildTileRoadLabelWidgets({
  required BuildContext context,
  required AppLocalizations l10n,
  required int? roadLevel,
}) {
  if (roadLevel == null) {
    return [Text(l10n.provinceOverlay_tileRoadNone, style: _fgBodyStyle())];
  }
  final theme = Theme.of(context);
  final roadCaptionStyle = (theme.textTheme.labelSmall ??
          const TextStyle(fontSize: 11))
      .copyWith(
    height: 1.25,
    color: EditorialMonoclePalette.muted,
  );
  return [
    Text(
      roadRailTransportLevelPrimaryLine(l10n, roadLevel),
      style: _fgBodyStyle(),
    ),
    Text(roadRailSupplementaryLabel(l10n, roadLevel), style: roadCaptionStyle),
    if (roadLevel == 1)
      Text(l10n.provinceOverlay_tileRoadRailGloss, style: roadCaptionStyle),
  ];
}
