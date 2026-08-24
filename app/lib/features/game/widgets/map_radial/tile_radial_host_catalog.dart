/// Catalog layout + spoke views for [GameMapTileRadialHost].
///
/// SPEC: `SPEC/ui/tile-context-radial.md`, `SPEC/ui/components/tile-radial-catalog.md`
/// (Refs #4440, #4570).
library;

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:flutter/widgets.dart';

import 'tile_radial_catalog.dart';
import 'tile_radial_keys.dart';
import 'tile_radial_spoke_view.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_copy.dart';
import 'tile_radial_tooltips.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/purchase_land_payoff_copy.dart';

String tileRadialProvinceIdFromTileKey(String tileKey) {
  final parsed = tileKey.split('|');
  return parsed.length >= 2 ? '${parsed[0]}|${parsed[1]}' : tileKey;
}

/// Ranked wedges / More remainder from overlay action visibility.
TileRadialCatalogLayout tileRadialHostCatalogLayout({
  required ct_models.Game game,
  required String humanPlayerId,
  required String tileKey,
  required RegionMapViewData region,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
}) {
  final states = ProvinceActionStateCalculator.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: tileKey,
    region: region,
    playerView: playerView,
    currentOrders: draftOrders,
    workTargetSelectionCache: workTargetSelectionCache,
    mapData: mapData,
  );
  final provinceId = tileRadialProvinceIdFromTileKey(tileKey);
  final upgradeTown =
      GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: provinceId,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: mapData?.combinedTopology,
        currentOrders: draftOrders,
        tileMapByRegion: mapData?.tileMapByRegion,
      );
  final upgradeTownOnSelectedTile =
      upgradeTown.showControl && upgradeTown.townTileKey == tileKey;
  return rankTileRadialCatalog(
    visibility: {
      TileRadialCatalogAction.explore: (
        showIcon: states.explore.showIcon,
        enabled: states.explore.enabled,
      ),
      TileRadialCatalogAction.prospect: (
        showIcon: states.prospect.showIcon,
        enabled: states.prospect.enabled,
      ),
      TileRadialCatalogAction.buildImprovement: (
        showIcon: states.buildImprovement.showIcon,
        enabled: states.buildImprovement.enabled,
      ),
      TileRadialCatalogAction.buildRoad: (
        showIcon: states.buildRoad.showIcon,
        enabled: states.buildRoad.enabled,
      ),
      TileRadialCatalogAction.purchaseLand: (
        showIcon: states.purchaseLand.showIcon,
        enabled: states.purchaseLand.enabled,
      ),
      TileRadialCatalogAction.upgradeTown: (
        showIcon: upgradeTownOnSelectedTile,
        enabled: upgradeTownOnSelectedTile && upgradeTown.enabled,
      ),
      TileRadialCatalogAction.buildPort: (
        showIcon: states.buildPort.showIcon,
        enabled: states.buildPort.enabled,
      ),
      TileRadialCatalogAction.buildRail: (
        showIcon: states.buildRail.showIcon,
        enabled: states.buildRail.enabled,
      ),
      TileRadialCatalogAction.buildFort: (
        showIcon: states.buildFort.showIcon,
        enabled: states.buildFort.enabled,
      ),
    },
  );
}

/// Label + tooltip views for ranked spokes.
List<TileRadialSpokeView> tileRadialHostSpokeViews({
  required BuildContext context,
  required AppLocalizations l10n,
  required ct_models.Game game,
  required String humanPlayerId,
  required String tileKey,
  required RegionMapViewData region,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
  required List<TileRadialSpoke> spokes,
}) {
  final provinceId = tileRadialProvinceIdFromTileKey(tileKey);
  final states = ProvinceActionStateCalculator.compute(
    game: game,
    humanPlayerId: humanPlayerId,
    selectedTileKey: tileKey,
    region: region,
    playerView: playerView,
    currentOrders: draftOrders,
    workTargetSelectionCache: workTargetSelectionCache,
    mapData: mapData,
  );
  final upgradeTown =
      GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: provinceId,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: mapData?.combinedTopology,
        currentOrders: draftOrders,
        tileMapByRegion: mapData?.tileMapByRegion,
      );
  bool hasMatchingUnits(TileRadialCatalogAction action) {
    switch (action) {
      case TileRadialCatalogAction.explore:
        return states.explore.hasMatchingUnits;
      case TileRadialCatalogAction.prospect:
        return states.prospect.hasMatchingUnits;
      case TileRadialCatalogAction.buildImprovement:
        return states.buildImprovement.hasMatchingUnits;
      case TileRadialCatalogAction.buildRoad:
        return states.buildRoad.hasMatchingUnits;
      case TileRadialCatalogAction.purchaseLand:
        return states.purchaseLand.hasMatchingUnits;
      case TileRadialCatalogAction.upgradeTown:
        return upgradeTown.hasBuilderUnits;
      case TileRadialCatalogAction.buildPort:
        return states.buildPort.hasMatchingUnits;
      case TileRadialCatalogAction.buildRail:
        return states.buildRail.hasMatchingUnits;
      case TileRadialCatalogAction.buildFort:
        return states.buildFort.hasMatchingUnits;
    }
  }

  return [
    for (final spoke in spokes)
      TileRadialSpokeView(
        action: spoke.action,
        enabled: spoke.enabled,
        label: tileRadialActionLabel(l10n, spoke.action),
        tooltip: tileRadialActionTooltip(
          context: context,
          l10n: l10n,
          action: spoke.action,
          game: game,
          humanPlayerId: humanPlayerId,
          tileKey: tileKey,
          provinceId: provinceId,
          currentOrders: draftOrders,
          enabled: spoke.enabled,
          hasMatchingUnits: hasMatchingUnits(spoke.action),
        ),
        caption: switch (spoke.action) {
          TileRadialCatalogAction.buildImprovement =>
            buildImprovementNextYieldGistForTile(
              l10n: l10n,
              game: game,
              humanPlayerId: humanPlayerId,
              tileKey: tileKey,
              enabled: spoke.enabled,
              mapData: mapData,
            ),
          TileRadialCatalogAction.purchaseLand => purchaseLandPayoffCopyForTile(
            l10n: l10n,
            game: game,
            tileKey: tileKey,
            enabled: spoke.enabled,
          )?.gist,
          _ => null,
        },
      ),
  ];
}
