/// Revealed-tile body for [ProvinceSeaZoneDetailOverlay] tile section.

import 'package:colonizethis_data/colonizethis_data.dart' show terrainDisplayName;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_designation.dart';
import 'province_sea_zone_detail_overlay_sections_economic_labels.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_section_labels.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart' show explorerConsulateGateBlocksMinorTribeProvince, isProspectableTerrain, isProspectableTerrainId;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView, resourceIdVisibleInPlayerView;

Widget buildRevealedTileSection({
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
  ProvinceTileConnectivityDisplay? tileConnectivity,
}) {
  final tileState = game.worldState.tileState;
  final resourceByTile = game.worldState.resourceByTileKey;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};
  final terrainStr = cell.terrainType != null
      ? terrainDisplayName(cell.terrainType!)
      : economicTerrainTitle(cell.terrainTypeId ?? '—');
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

  final tileOwnerId = findProvinceForSeaZoneOverlay(game, provinceId)?.ownerId;
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
          style: overlayFgBodyStyle(),
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
        child: buildTileImprovementLabel(
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

  final bodyStyle = overlayFgBodyStyle();
  final designationLine = provinceOverlayTileDesignationLine(
    l10n: l10n,
    game: game,
    provinceId: provinceId,
    selectedTileKey: selectedTileKey,
  );
  return buildOverlaySection(
    l10n.provinceOverlay_sectionTile,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.provinceOverlay_tileCoordinates(x, y), style: bodyStyle),
        Text(l10n.provinceOverlay_tileTerrain(terrainStr), style: bodyStyle),
        if (designationLine != null)
          Text(designationLine, style: bodyStyle),
        buildTileResourceLabelRow(
          context: context,
          l10n: l10n,
          resourceVisible: resourceVisible,
          resourceLabel: resourceLabel,
        ),
        prospectedRow,
        improvementRow,
        ...buildTileRoadLabelWidgets(
          context: context,
          l10n: l10n,
          roadLevel: roadLevel,
        ),
        ...buildTileConnectivityLabelWidgets(
          l10n: l10n,
          tileConnectivity: tileConnectivity,
        ),
        Text(
          l10n.provinceOverlay_tileCivilianUnits(civilianCount),
          style: bodyStyle,
        ),
      ],
    ),
  );
}
