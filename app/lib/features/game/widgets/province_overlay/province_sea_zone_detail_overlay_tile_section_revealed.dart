/// Revealed-tile body for [ProvinceSeaZoneDetailOverlay] tile section.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'province_sea_zone_detail_overlay.dart';

Widget _buildRevealedTileSection({
  required BuildContext context,
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required int civilianCount,
  required String selectedTileKey,
  required int x,
  required int y,
  required CellViewData cell,
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
