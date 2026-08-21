/// Overlay-matching tooltips for MAP30001 / MAP30002 catalog actions.
library;

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_sections_political.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_overlay_tooltips.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show explorerConsulateGateBlocksMinorTribeProvince;
import 'package:flutter/widgets.dart';

import '../../../../config/constants.dart' show kNarrowBreakpoint;
import 'tile_radial_catalog.dart';

String tileRadialActionTooltip({
  required BuildContext context,
  required AppLocalizations l10n,
  required TileRadialCatalogAction action,
  required Game game,
  required String humanPlayerId,
  required String tileKey,
  required String provinceId,
  required Orders currentOrders,
  required bool enabled,
  required bool hasMatchingUnits,
}) {
  switch (action) {
    case TileRadialCatalogAction.explore:
    case TileRadialCatalogAction.prospect:
      final tileOwnerId = findProvinceForSeaZoneOverlay(
        game,
        provinceId,
      )?.ownerId;
      final consulateGated = explorerConsulateGateBlocksMinorTribeProvince(
        game: game,
        playerId: humanPlayerId,
        provinceOwnerId: tileOwnerId,
      );
      if (!enabled && consulateGated) {
        return MediaQuery.sizeOf(context).width < kNarrowBreakpoint
            ? l10n.provinceOverlay_tileConsulateRequiredForExploreNarrowTooltip
            : l10n.provinceOverlay_tileConsulateRequiredForExploreTooltip;
      }
      return action == TileRadialCatalogAction.explore
          ? l10n.provinceOverlay_tileExploreWithExplorerTooltip
          : l10n.provinceOverlay_tileProspectWithExplorerTooltip;
    case TileRadialCatalogAction.buildImprovement:
      return provinceOverlayBuildImprovementTooltip(
        l10n: l10n,
        game: game,
        humanPlayerId: humanPlayerId,
        currentOrders: currentOrders,
        selectedTileKey: tileKey,
        enabled: enabled,
        hasMatchingUnits: hasMatchingUnits,
      );
    case TileRadialCatalogAction.buildRoad:
      return provinceOverlayBuildRoadTooltip(
        l10n: l10n,
        game: game,
        humanPlayerId: humanPlayerId,
        currentOrders: currentOrders,
        selectedTileKey: tileKey,
        enabled: enabled,
        hasMatchingUnits: hasMatchingUnits,
      );
    case TileRadialCatalogAction.purchaseLand:
      return provinceOverlayPurchaseLandTooltip(
        l10n: l10n,
        game: game,
        humanPlayerId: humanPlayerId,
        currentOrders: currentOrders,
        selectedTileKey: tileKey,
        provinceId: provinceId,
        enabled: enabled,
        hasMatchingUnits: hasMatchingUnits,
      );
    case TileRadialCatalogAction.upgradeTown:
      return provinceOverlayPoliticalUpgradeTownTooltip(
        l10n: l10n,
        game: game,
        humanPlayerId: humanPlayerId,
        currentOrders: currentOrders,
        townTileKey: tileKey,
        enabled: enabled,
        hasBuilderUnits: hasMatchingUnits,
      );
    case TileRadialCatalogAction.buildPort:
      return provinceOverlayBuildPortTooltip(
        l10n: l10n,
        game: game,
        humanPlayerId: humanPlayerId,
        currentOrders: currentOrders,
        selectedTileKey: tileKey,
        enabled: enabled,
        hasMatchingUnits: hasMatchingUnits,
      );
    case TileRadialCatalogAction.buildRail:
      return provinceOverlayBuildRailroadTooltip(
        l10n: l10n,
        game: game,
        humanPlayerId: humanPlayerId,
        currentOrders: currentOrders,
        selectedTileKey: tileKey,
        enabled: enabled,
        hasMatchingUnits: hasMatchingUnits,
      );
    case TileRadialCatalogAction.buildFort:
      return provinceOverlayBuildFortTooltip(
        l10n: l10n,
        game: game,
        humanPlayerId: humanPlayerId,
        currentOrders: currentOrders,
        selectedTileKey: tileKey,
        enabled: enabled,
        hasMatchingUnits: hasMatchingUnits,
      );
  }
}
