/// Tile section helpers and builder for [ProvinceSeaZoneDetailOverlay].

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
    // SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
    // § Dark-theme Tile section placeholder body tokens (S5 follow-up).
    // The no-selection guidance prompt is placeholder copy, not live
    // world-state data, so it resolves to the muted token rather than
    // falling through `DefaultTextStyle` to the Material `bodyMedium`.
    return _buildSection(
      l10n.provinceOverlay_sectionTile,
      Text(
        l10n.provinceOverlay_clickTileForDetails,
        style: TextStyle(color: EditorialMonoclePalette.muted),
      ),
    );
  }
  final coords = tryParseProvinceOverlayTileCoords(
    regionId: region.regionId,
    regionWidth: region.width,
    regionHeight: region.height,
    selectedTileKey: selectedTileKey,
  );
  if (coords == null) {
    // SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
    // § Dark-theme Tile section placeholder body tokens (S5 follow-up).
    // Reuse the shared S9 em-dash helper so every `Text('—')` placeholder
    // surface in the overlay resolves to one muted token source.
    return _buildSection(
      l10n.provinceOverlay_sectionTile,
      _emptyBodyDashText(),
    );
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
  // R13 (#3573): the Tile-section terrain row shows the canonical title-cased
  // display name for known terrain types, never the raw enum `.name`; the
  // string-id fallback is title-cased (camelCase spaced) via the shared helper.
  final terrainStr = cell.terrainType != null
      ? terrainDisplayName(cell.terrainType!)
      : _economicTerrainTitle(cell.terrainTypeId ?? '—');
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
    l10n,
    terrainProspectable: prospectable,
    playerHasProspected: prospected.contains(selectedTileKey),
  );
  final impLevel = tileState.improvementLevel(selectedTileKey);
  final roadLevel = cell.isSea ? null : tileState.roadLevel(selectedTileKey);

  // Refs #3753 R4b: when the Explore/Prospect inline action is disabled solely
  // because the issuing GP holds no Consulate with the owning Minor/Tribe, the
  // tooltip explains the gate ("Establish a consulate before exploring or
  // prospecting") instead of the default action hint. Mirrors the order-engine
  // submission gate via the shared predicate.
  final tileOwnerId = _findProvince(game, provinceId)?.ownerId;
  final consulateGated = explorerConsulateGateBlocksMinorTribeProvince(
    game: game,
    playerId: humanPlayerId,
    provinceOwnerId: tileOwnerId,
  );
  final exploreTooltip = (!exploreActionEnabled && consulateGated)
      ? l10n.provinceOverlay_tileConsulateRequiredForExploreTooltip
      : l10n.provinceOverlay_tileExploreWithExplorerTooltip;
  final prospectTooltip = (!prospectActionEnabled && consulateGated)
      ? l10n.provinceOverlay_tileConsulateRequiredForExploreTooltip
      : l10n.provinceOverlay_tileProspectWithExplorerTooltip;

  final prospectedRow = Row(
    children: [
      Expanded(
        child: Text(
          l10n.provinceOverlay_tileProspected(prospectedLabel),
          style: _fgBodyStyle(),
        ),
      ),
      if (showExploreActionIcon)
        CtIconAction(
          tooltip: exploreTooltip,
          onPressed: exploreActionEnabled ? onExploreWithExplorerTap : null,
          icon: Icons.explore,
          enabled: exploreActionEnabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
      if (showProspectActionIcon)
        CtIconAction(
          tooltip: prospectTooltip,
          onPressed: prospectActionEnabled ? onProspectWithExplorerTap : null,
          icon: Icons.travel_explore,
          enabled: prospectActionEnabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
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
        CtIconAction(
          tooltip: l10n.provinceOverlay_tileBuildImprovementTooltip,
          onPressed: buildImprovementActionEnabled
              ? onBuildImprovementTap
              : null,
          icon: Icons.handyman,
          enabled: buildImprovementActionEnabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
    ],
  );

  // Dark-theme tokens (Refs #2865, SPEC § Dark-theme Tile section body
  // tokens — live-data body rows). Every Tile row that renders exact
  // world-state values resolves its TextStyle.color to
  // EditorialMonoclePalette.fg via the shared `_fgBodyStyle()` helper so
  // the editorial-monocle dark theme owns the Tile live-data surface
  // end-to-end. Rows in scope: coordinates, terrain, civilian-units count
  // (below), plus the Prospected, Improvement, road / railroad primary
  // numeric line, and sea-tile no-road row (pinned in `prospectedRow`,
  // `_buildTileImprovementLabel`, and `_buildTileRoadLabelWidgets`). The
  // helper centralises the canonical fg token shared with Political,
  // Tile, Economic improved-row, Military owner sub-header, Civilian
  // own-unit, and Naval fleet-summary live-data rows.
  final bodyStyle = _fgBodyStyle();
  final designationLine = provinceOverlayTileDesignationLine(
    l10n: l10n,
    game: game,
    provinceId: provinceId,
    selectedTileKey: selectedTileKey,
  );
  return _buildSection(
    l10n.provinceOverlay_sectionTile,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.provinceOverlay_tileCoordinates(x, y), style: bodyStyle),
        Text(l10n.provinceOverlay_tileTerrain(terrainStr), style: bodyStyle),
        if (designationLine != null)
          Text(designationLine, style: bodyStyle),
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
        Text(
          l10n.provinceOverlay_tileCivilianUnits(civilianCount),
          style: bodyStyle,
        ),
      ],
    ),
  );
}
