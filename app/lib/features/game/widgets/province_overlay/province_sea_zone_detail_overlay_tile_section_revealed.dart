/// Revealed-tile body for [ProvinceSeaZoneDetailOverlay] tile section.
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show terrainDisplayName;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart'
    show ProvinceBlockadeStatus;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../config/constants.dart' show kNarrowBreakpoint;
import 'province_sea_zone_detail_overlay_designation.dart';
import 'province_sea_zone_detail_overlay_sections_economic_labels.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_gist_line.dart';
import 'province_sea_zone_detail_overlay_tile_section_labels.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_preview_ui.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        explorerConsulateGateBlocksMinorTribeProvince,
        isProspectableTerrain,
        isProspectableTerrainId;
import 'package:colonizethis_world/colonizethis_world.dart'
    show PlayerView, resourceIdVisibleInPlayerView;

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
  required ProvinceActionStates civilianInlineActions,
  required ProvinceInlineActionCallbacks inlineActionCallbacks,
  required Orders currentOrders,
  ProvinceTileConnectivityDisplay? tileConnectivity,
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
}) {
  final explore = civilianInlineActions.explore;
  final prospect = civilianInlineActions.prospect;
  final buildImprovement = civilianInlineActions.buildImprovement;
  final purchaseLand = civilianInlineActions.purchaseLand;
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
  final consulateTooltip = MediaQuery.sizeOf(context).width < kNarrowBreakpoint
      ? l10n.provinceOverlay_tileConsulateRequiredForExploreNarrowTooltip
      : l10n.provinceOverlay_tileConsulateRequiredForExploreTooltip;
  final exploreTooltip = (!explore.enabled && consulateGated)
      ? consulateTooltip
      : l10n.provinceOverlay_tileExploreWithExplorerTooltip;
  final prospectTooltip = (!prospect.enabled && consulateGated)
      ? consulateTooltip
      : l10n.provinceOverlay_tileProspectWithExplorerTooltip;

  final prospectedRow = Row(
    children: [
      Expanded(
        child: Text(
          l10n.provinceOverlay_tileProspected(prospectedLabel),
          style: overlayFgBodyStyle(),
        ),
      ),
      if (explore.showIcon)
        CtIconAction(
          tooltip: exploreTooltip,
          onPressed: explore.enabled
              ? inlineActionCallbacks.onExploreWithExplorerTap
              : null,
          icon: Icons.explore,
          enabled: explore.enabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
      if (prospect.showIcon)
        CtIconAction(
          tooltip: prospectTooltip,
          onPressed: prospect.enabled
              ? inlineActionCallbacks.onProspectWithExplorerTap
              : null,
          icon: Icons.travel_explore,
          enabled: prospect.enabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
    ],
  );
  final buildImprovementTooltip = provinceOverlayBuildImprovementTooltip(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    currentOrders: currentOrders,
    selectedTileKey: selectedTileKey,
    enabled: buildImprovement.enabled,
    hasMatchingUnits: buildImprovement.hasMatchingUnits,
  );
  final nextYieldPreview = tileConnectivity?.nextImproveYield;
  final nextYieldGist = buildImprovement.enabled && nextYieldPreview != null
      ? buildImprovementNextYieldGistLine(
          l10n: l10n,
          preview: nextYieldPreview,
        )
      : null;
  final improvementIconRow = Row(
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
      if (buildImprovement.showIcon)
        CtIconAction(
          tooltip: buildImprovementTooltip,
          onPressed: buildImprovement.enabled
              ? inlineActionCallbacks.onBuildImprovementTap
              : null,
          icon: Icons.handyman,
          enabled: buildImprovement.enabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
    ],
  );
  final improvementRow = nextYieldGist == null
      ? improvementIconRow
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            improvementIconRow,
            BuildImprovementYieldGistLine(text: nextYieldGist),
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
        if (designationLine != null) Text(designationLine, style: bodyStyle),
        buildTileResourceLabelRow(
          context: context,
          l10n: l10n,
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          selectedTileKey: selectedTileKey,
          provinceId: provinceId,
          resourceVisible: resourceVisible,
          resourceLabel: resourceLabel,
          purchaseLandAction: purchaseLand,
          onPurchaseLandTap: inlineActionCallbacks.onPurchaseLandTap,
        ),
        prospectedRow,
        improvementRow,
        ...buildTileRoadLabelWidgets(
          context: context,
          l10n: l10n,
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          selectedTileKey: selectedTileKey,
          provinceId: provinceId,
          roadLevel: roadLevel,
          buildRoadAction: civilianInlineActions.buildRoad,
          onBuildRoadTap: inlineActionCallbacks.onBuildRoadTap,
          buildPortAction: civilianInlineActions.buildPort,
          onBuildPortTap: inlineActionCallbacks.onBuildPortTap,
          buildRailAction: civilianInlineActions.buildRail,
          onBuildRailroadTap: inlineActionCallbacks.onBuildRailroadTap,
          tileConnectivity: tileConnectivity,
          blockadeStatus: blockadeStatus,
        ),
        ...buildTileConnectivityLabelWidgets(
          context: context,
          l10n: l10n,
          game: game,
          humanPlayerId: humanPlayerId,
          provinceId: provinceId,
          roadLevel: roadLevel,
          tileConnectivity: tileConnectivity,
          blockadeStatus: blockadeStatus,
        ),
        Text(
          l10n.provinceOverlay_tileCivilianUnits(civilianCount),
          style: bodyStyle,
        ),
      ],
    ),
  );
}
