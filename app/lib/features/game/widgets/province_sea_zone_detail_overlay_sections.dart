/// Supplementary GDD label for [roadLevel] on land tiles (issue #1537 / extraction-and-improvements § Transport Level).

part of 'province_sea_zone_detail_overlay.dart';

@visibleForTesting
String roadRailSupplementaryLabel(int roadLevel) {
  return switch (roadLevel) {
    0 => 'none',
    1 => 'primitive road',
    2 => 'improved road',
    4 => 'port or railroad',
    _ => 'non-standard transport level',
  };
}

/// Gloss under level 1 so “primitive road” is not read as railroad.
@visibleForTesting
const String kRoadRailPrimitiveVersusRailGloss =
    'Basic land link for connectivity and yield caps. Railroads are transport level 4.';

/// Primary Tile-section line for land tiles; [transportLevel] is stored road/rail level.
@visibleForTesting
String roadRailTransportLevelPrimaryLine(int transportLevel) {
  return 'Road / railroad: transport level $transportLevel';
}

/// Ordered text lines for Tile “Road / railroad” (null → sea / no land transport row).
@visibleForTesting
List<String> roadRailTileDetailLinesForTests({required int? transportLevel}) {
  if (transportLevel == null) {
    return const ['Road / railroad: —'];
  }
  final v = transportLevel;
  final lines = <String>[
    roadRailTransportLevelPrimaryLine(v),
    roadRailSupplementaryLabel(v),
  ];
  if (v == 1) {
    lines.add(kRoadRailPrimitiveVersusRailGloss);
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
String tileDetailProspectedDisplayLabel({
  required bool terrainProspectable,
  required bool playerHasProspected,
}) {
  if (!terrainProspectable) return '—';
  return playerHasProspected ? 'yes' : 'no';
}

Widget _buildTileResourceLabelRow({
  required BuildContext context,
  required AppLocalizations l10n,
  required String? resourceVisible,
  required String resourceLabel,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(l10n.provinceOverlay_tileResourcePrefix),
      if (resourceVisible != null)
        ResourceLabelInline(commodityId: resourceVisible)
      else
        Text(resourceLabel),
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
    impLevel: impLevel,
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return Text(l10n.provinceOverlay_tileImprovement(improvementLine));
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
    return [Text(l10n.provinceOverlay_tileRoadNone)];
  }
  final roadCaptionStyle = TextStyle(
    fontSize: 11,
    height: 1.25,
    color: EditorialMonoclePalette.muted,
  );
  return [
    Text(roadRailTransportLevelPrimaryLine(roadLevel)),
    Text(roadRailSupplementaryLabel(roadLevel), style: roadCaptionStyle),
    if (roadLevel == 1)
      Text(kRoadRailPrimitiveVersusRailGloss, style: roadCaptionStyle),
  ];
}

class _OverlayContent {
  _OverlayContent({
    required this.tabLabels,
    required this.tabViews,
    required this.sections,
  });
  final List<String> tabLabels;
  final List<Widget> tabViews;
  final Widget sections;
}

String? _economicTerrainTitleForTile(RegionMapViewData region, String tk) {
  final parsed = tryParseTileKey(tk);
  if (parsed == null || parsed.regionId != region.regionId) return null;
  final x = parsed.x;
  final y = parsed.y;
  if (x < 0 || y < 0 || x >= region.width || y >= region.height) {
    return null;
  }
  final cell = region.cellAt(x, y);
  final raw = cell.terrainType?.name ?? cell.terrainTypeId ?? '—';
  return _economicTerrainTitle(raw);
}

String _economicTerrainTitle(String raw) {
  if (raw.isEmpty || raw == '—') return raw;
  return raw
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

Widget _economicHoverRow({
  required String tileKey,
  required void Function(String?)? onHighlightTile,
  required Widget child,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => onHighlightTile?.call(tileKey),
    onExit: (_) => onHighlightTile?.call(null),
    child: Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: child,
    ),
  );
}

String _ownerName(Game game, String? ownerId) {
  if (ownerId == null || ownerId.isEmpty) return 'Unclaimed';
  for (final p in game.players) {
    if (p.id == ownerId) return p.displayName;
  }
  for (final m in game.minorNations) {
    if (m.id == ownerId) return m.displayName ?? m.id;
  }
  for (final t in game.tribes) {
    if (t.id == ownerId) return t.displayName ?? t.id;
  }
  return ownerId;
}

String _improvementNameForResource(String? resourceId) {
  if (resourceId == null) return 'Improvement';
  switch (resourceId) {
    case 'grain':
      return 'Farm';
    case 'meat':
    case 'horses':
      return 'Ranch';
    case 'wool':
      return 'Pasture';
    case 'timber':
      return 'Lumber camp';
    case 'sugarCane':
    case 'tobacco':
    case 'cotton':
    case 'spices':
      return 'Plantation';
    case 'furs':
      return 'Fur post';
    case 'iron':
    case 'copper':
    case 'tin':
    case 'coal':
    case 'silver':
    case 'gold':
    case 'gems':
    case 'diamonds':
      return 'Mine';
    default:
      return 'Improvement';
  }
}

String _improvementBaseNameForPlayer({
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (visibleResourceId != null) {
    return _improvementNameForResource(visibleResourceId);
  }
  if (rawResourceId != null &&
      kProspectRequiredResourceIds.contains(rawResourceId)) {
    return 'Mine';
  }
  if (rawResourceId != null) {
    return _improvementNameForResource(rawResourceId);
  }
  return 'Improvement';
}

String _improvementLabelForTileDetail({
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (impLevel <= 0) {
    return '—';
  }
  final base = _improvementBaseNameForPlayer(
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return '$base L$impLevel';
}

Widget _buildPoliticalSection({
  required AppLocalizations l10n,
  required String name,
  required String ownerName,
}) {
  // Dark-theme tokens (Refs #2865, SPEC § Dark-theme Political section body
  // tokens). Both body rows declare TextStyle.color explicitly so the
  // editorial-monocle dark theme owns this surface and the section stops
  // inheriting DefaultTextStyle / Material bodyMedium colours.
  // `EditorialMonoclePalette.fg` is a runtime getter (OKLCH → Color), so the
  // style cannot be `const`.
  final bodyStyle = TextStyle(color: EditorialMonoclePalette.fg);
  return _buildSection(
    l10n.provinceOverlay_sectionPolitical,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.provinceOverlay_name(name), style: bodyStyle),
        Text(l10n.provinceOverlay_owner(ownerName), style: bodyStyle),
      ],
    ),
  );
}

Widget _buildTileSection({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required int civilianCount,
  String? selectedTileKey,
  required bool showExploreActionIcon,
  required bool exploreActionEnabled,
  VoidCallback? onExploreWithExplorerTap,
  required bool showProspectActionIcon,
  required bool prospectActionEnabled,
  VoidCallback? onProspectWithExplorerTap,
  required bool showBuildImprovementActionIcon,
  required bool buildImprovementActionEnabled,
  VoidCallback? onBuildImprovementTap,
}) {
  if (selectedTileKey == null) {
    return _buildSection(
      l10n.provinceOverlay_sectionTile,
      Text(l10n.provinceOverlay_clickTileForDetails),
    );
  }
  final coords = tryParseProvinceOverlayTileCoords(
    regionId: region.regionId,
    regionWidth: region.width,
    regionHeight: region.height,
    selectedTileKey: selectedTileKey,
  );
  if (coords == null) {
    return _buildSection(l10n.provinceOverlay_sectionTile, const Text('—'));
  }
  final x = coords.x;
  final y = coords.y;
  final cell = region.cellAt(x, y);
  if (cell.visibility == TileVisibility.unrevealed) {
    return _buildSection(
      l10n.provinceOverlay_sectionTile,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _obfuscatedBodyText(l10n.provinceOverlay_tileCoordinatesUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileTerrainUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileResourceUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileProspectedUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileImprovementUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileRoadUnknown),
          _obfuscatedBodyText(l10n.provinceOverlay_tileCivilianUnitsUnknown),
        ],
      ),
    );
  }
  final tileState = game.worldState.tileState;
  final resourceByTile = game.worldState.resourceByTileKey;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};
  final terrainStr = cell.terrainType?.name ?? cell.terrainTypeId ?? '—';
  final resourceRaw = resourceByTile[selectedTileKey] ?? cell.resourceId;
  final visLevel = playerView.visibilityForTile(selectedTileKey);
  final resourceVisible = resourceIdVisibleInPlayerView(
    playerView,
    selectedTileKey,
    resourceRaw,
  );
  final resourceLabel = resourceVisible ?? '—';
  final prospectable = cell.terrainType != null
      ? isProspectableTerrain(cell.terrainType!)
      : isProspectableTerrainId(cell.terrainTypeId);
  final prospectedLabel = tileDetailProspectedDisplayLabel(
    terrainProspectable: prospectable,
    playerHasProspected: prospected.contains(selectedTileKey),
  );
  final impLevel = tileState.improvementLevel(selectedTileKey);
  final roadLevel = cell.isSea ? null : tileState.roadLevel(selectedTileKey);

  final prospectedRow = Row(
    children: [
      Expanded(
        child: Text(l10n.provinceOverlay_tileProspected(prospectedLabel)),
      ),
      if (showExploreActionIcon)
        IconButton(
          tooltip: l10n.provinceOverlay_tileExploreWithExplorerTooltip,
          onPressed: exploreActionEnabled ? onExploreWithExplorerTap : null,
          icon: Icon(
            Icons.explore,
            color: exploreActionEnabled
                ? null
                : EditorialMonoclePalette.muted.withValues(
                    alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
                  ),
          ),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
        ),
      if (showProspectActionIcon)
        IconButton(
          tooltip: l10n.provinceOverlay_tileProspectWithExplorerTooltip,
          onPressed: prospectActionEnabled ? onProspectWithExplorerTap : null,
          icon: Icon(
            Icons.travel_explore,
            color: prospectActionEnabled
                ? null
                : EditorialMonoclePalette.muted.withValues(
                    alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
                  ),
          ),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
        ),
    ],
  );
  final improvementRow = Row(
    children: [
      Expanded(
        child: _buildTileImprovementLabel(
          l10n: l10n,
          impLevel: impLevel,
          visLevel: visLevel,
          rawResourceId: resourceRaw,
          visibleResourceId: resourceVisible,
        ),
      ),
      if (showBuildImprovementActionIcon)
        IconButton(
          tooltip: l10n.provinceOverlay_tileBuildImprovementTooltip,
          onPressed: buildImprovementActionEnabled
              ? onBuildImprovementTap
              : null,
          icon: Icon(
            Icons.handyman,
            color: buildImprovementActionEnabled
                ? null
                : EditorialMonoclePalette.muted.withValues(
                    alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
                  ),
          ),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
        ),
    ],
  );

  return _buildSection(
    l10n.provinceOverlay_sectionTile,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.provinceOverlay_tileCoordinates(x, y)),
        Text(l10n.provinceOverlay_tileTerrain(terrainStr)),
        _buildTileResourceLabelRow(
          context: context,
          l10n: l10n,
          resourceVisible: resourceVisible,
          resourceLabel: resourceLabel,
        ),
        prospectedRow,
        improvementRow,
        ..._buildTileRoadLabelWidgets(
          context: context,
          l10n: l10n,
          roadLevel: roadLevel,
        ),
        Text(l10n.provinceOverlay_tileCivilianUnits(civilianCount)),
      ],
    ),
  );
}

Province? _findProvince(Game game, String provinceId) {
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.id == provinceId) return p;
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.id == provinceId) return p;
  }
  return null;
}

// Section header band shared by every province / sea-zone tab body and the
// wide-layout `sections` column. Renders the canonical CtSectionLabel
// (Refs #2859 R9) so the title inherits the dark editorial-monocle
// small-caps + `--accent-dim` underline contract; see
// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme section labels.
//
// When [title] is empty (e.g. the narrow-layout obfuscated tab body that
// already has its label rendered by `CtTabStrip`), the header band is
// omitted entirely so the obfuscated body does not paint an extra
// underline beneath the tab strip.
Widget _buildSection(String title, Widget child) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty) ...[
          CtSectionLabel(title),
          const SizedBox(height: 4),
        ],
        child,
      ],
    ),
  );
}

class _ObfuscatedSection extends StatelessWidget {
  const _ObfuscatedSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _buildSection('', _obfuscatedBodyText(l10n.provinceOverlay_unknown));
  }
}
