/// Colonial acquisition gate / iteration helpers (Refs #4079; #4365 Slice A).
library;

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';

/// Tribe ids that are already [playerId]'s own colony
/// (`ColonyState.colonyOfGpId == playerId`).
///
/// Colony tribes stay in the game and keep owning NW provinces after Tribe
/// Join Empire resolves, so they remain in the invadable list. The acquisition
/// arms exclude these owners so the planner never re-targets its own colony
/// (Refs #3758 R4 / S3; SPEC/ai/phase-planner-architecture.md § Own-colony
/// exclusion; SPEC/game/diplomacy.md § GP–Tribe Join Empire → colony). Colonies
/// of a different GP are intentionally not excluded.
Set<String> acquisitionOwnColonyTribeIds(Game game, String playerId) => <String>{
  for (final colony in game.colonyStates)
    if (colony.colonyOfGpId == playerId) colony.tribeId,
};

/// Iteration order over NW invadable provinces for
/// [planColonialAcquisition], honoring the spec's adjacency-distance
/// requirement (Refs #2509 § COLONIAL phase planner §
/// planColonialAcquisition -- "sorted by adjacency distance to owned
/// territory").
///
/// Returns [ColonialSummary.invadableNewWorldProvinceIdsByDistance]
/// when the snapshot was built with a [MapTopology] (the normal
/// production path; the perception-snapshot builder populates the
/// distance-sorted field via
/// [reachableNonOwnedProvinceDistancesViaSeas]). Falls back to the
/// lex-sorted [ColonialSummary.invadableNewWorldProvinceIdsSorted]
/// for synthetic fixtures that build snapshots without a topology
/// (today: the COLONIAL acquisition unit tests). The fallback
/// preserves backward-compatible behavior for the legacy pin set
/// (sort-by-province-id tiebreaks) while production play uses the
/// distance-sorted iteration the spec mandates.
///
/// The function never throws or returns null: if the snapshot has
/// neither field populated (e.g. an outer COLONIAL guard already
/// short-circuited to an empty invadable set upstream), it returns
/// the empty list and the caller's outer-guard short-circuits as
/// today.
List<String> acquisitionIterationOrder(ColonialSummary colonial) {
  if (colonial.invadableNewWorldProvinceIdsByDistance.isNotEmpty) {
    return colonial.invadableNewWorldProvinceIdsByDistance;
  }
  return colonial.invadableNewWorldProvinceIdsSorted;
}

/// True when [playerId] owns at least one [kUnitTypeMerchant] unit
/// with [UnitStatus.idle] in either region. Region of the Merchant is
/// not constrained — the orchestrator and resolver handle staging
/// movement on follow-up turns (mirrors the Builder selection
/// convention in [planColonialCivilian]).
bool acquisitionHasIdleMerchant(WorldState world, String playerId) {
  for (final unit in allUnitsFromWorld(world)) {
    if (unit.ownerId == playerId &&
        unit.type == kUnitTypeMerchant &&
        unit.status == UnitStatus.idle) {
      return true;
    }
  }
  return false;
}

/// True when [provinceId] contains at least one tile satisfying every
/// per-tile gate from `precheckPurchaseLand`:
///
///   - non-empty resource id in [WorldState.resourceByTileKey];
///   - not present in [purchasedByTile] (no other GP has bought it,
///     and the active player has not already purchased it either);
///   - mineral resource ids ([kMineralResourceIds]) require the tile
///     to be in [prospected] (the active player's prospected-tile
///     set);
///   - [purchaseLandCost] for the resource must be within [treasury].
///
/// Iteration over [WorldState.resourceByTileKey] is bounded by the
/// total number of tiles with a resource entry (much smaller than the
/// global tile count); per-tile checks are O(1). The function returns
/// the existence answer only — picking a specific tile for the
/// `purchase_land` work order is the orchestrator's job (the planner
/// contract returns the *target faction* and the *method*, not the
/// exact tile, mirroring the [AcquisitionMethod.joinEmpire] return
/// shape).
bool acquisitionProvinceHasValidPurchaseLandTile({
  required WorldState world,
  required String provinceId,
  required int treasury,
  required Set<String> prospected,
  required Map<String, String> purchasedByTile,
}) {
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    if (Unit.provinceIdFromTileKey(tileKey) != provinceId) continue;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    if (purchasedByTile.containsKey(tileKey)) continue;
    if (kMineralResourceIds.contains(resourceId) &&
        !prospected.contains(tileKey)) {
      continue;
    }
    if (treasury < purchaseLandCost(resourceId)) continue;
    return true;
  }
  return false;
}
