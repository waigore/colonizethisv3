/// Sole-cause Train {type} offer for MAP20001 / MAP30001 / MAP30002.
///
/// SPEC: `SPEC/ui/province-sea-zone-detail-overlay.md` (Refs #4752).
library;

import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_assignable.dart'
    show ProvinceInlineActionState;
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdNationalBureaucracy;
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Civilian hire kind offered from a map work shortcut.
enum MapTrainCivilianKind { explorer, builder, engineer, merchant, railBuilder }

/// True when disablement is solely `hasMatchingUnits == false`.
bool offerMapTrainCivilian({
  required bool showIcon,
  required bool hasMatchingUnits,
  required bool otherNonUnitGateApplies,
  required bool trainTapAvailable,
}) {
  return showIcon &&
      !hasMatchingUnits &&
      !otherNonUnitGateApplies &&
      trainTapAvailable;
}

/// Overlay inline-action convenience for [offerMapTrainCivilian].
bool offerMapTrainCivilianForState({
  required ProvinceInlineActionState state,
  required bool otherNonUnitGateApplies,
  required bool trainTapAvailable,
}) {
  return offerMapTrainCivilian(
    showIcon: state.showIcon,
    hasMatchingUnits: state.hasMatchingUnits,
    otherNonUnitGateApplies: otherNonUnitGateApplies,
    trainTapAvailable: trainTapAvailable,
  );
}

MapTrainCivilianKind mapTrainCivilianKindForRadialAction(
  TileRadialCatalogAction action,
) {
  switch (action) {
    case TileRadialCatalogAction.explore:
    case TileRadialCatalogAction.prospect:
      return MapTrainCivilianKind.explorer;
    case TileRadialCatalogAction.buildImprovement:
    case TileRadialCatalogAction.upgradeTown:
      return MapTrainCivilianKind.builder;
    case TileRadialCatalogAction.buildRoad:
    case TileRadialCatalogAction.buildPort:
    case TileRadialCatalogAction.buildFort:
      return MapTrainCivilianKind.engineer;
    case TileRadialCatalogAction.purchaseLand:
      return MapTrainCivilianKind.merchant;
    case TileRadialCatalogAction.buildRail:
      return MapTrainCivilianKind.railBuilder;
  }
}

/// Embassy / at-war gate for Purchase land (independent of Merchant units).
bool mapTrainPurchaseLandEmbassyGateApplies({
  required Game game,
  required String humanPlayerId,
  required String provinceId,
}) {
  final ownerId = game.worldState.tryGetProvince(provinceId)?.ownerId;
  if (ownerId == null || ownerId.isEmpty || ownerId == humanPlayerId) {
    return false;
  }
  final rel = getRelation(game, humanPlayerId, ownerId);
  final overture = getOverture(game, humanPlayerId, ownerId);
  return rel?.atWar == true || overture == null || !overture.hasEmbassy;
}

/// National Bureaucracy gate for Upgrade town (independent of Builder units).
bool mapTrainUpgradeTownTechGateApplies({
  required Game game,
  required String humanPlayerId,
}) {
  final player = game.playerById(humanPlayerId);
  return player?.techUnlocked?[kTechIdNationalBureaucracy] != true;
}

/// Materials / treasury shortfall that would disable work even with a unit.
bool mapTrainWorkAffordGateApplies({
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String tileKey,
  required String workTarget,
}) {
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: humanPlayerId,
    currentOrders: currentOrders,
    workTarget: workTarget,
    targetTileKey: tileKey,
  );
  if (!preview.hasCostPreview || preview.canAfford) return false;
  return preview.materialShortfalls.isNotEmpty ||
      preview.treasuryShortfall != null;
}
