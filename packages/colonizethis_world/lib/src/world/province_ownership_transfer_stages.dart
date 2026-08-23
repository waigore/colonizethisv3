import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'civilian_tile_occupancy.dart';
import 'faction_membership.dart';
import 'unit_lookup.dart';

/// Named stage helpers for canonical province ownership transfer (Refs #4038).
/// Orchestration stays in [province_ownership_transfer.dart]; these helpers are
/// pure/world-local steps unit-tested in isolation.
/// Authority: SPEC/program/province-ownership-transfer-stages.md.

/// Removes purchased-land entries whose tile province matches [conqueredProvinceId].
///
/// Invokes [onRemoved] with the number of entries dropped. Returns the filtered
/// map (or the original map when empty / unchanged reference when no purchases).
Map<String, String> clearPurchasedTilesForProvinceOwnershipTransfer(
  WorldState worldState,
  String conqueredProvinceId,
  void Function(int removed) onRemoved,
) {
  final existing = worldState.purchasedTilesByTileKey;
  if (existing.isEmpty) {
    onRemoved(0);
    return existing;
  }

  var removed = 0;
  final filtered = <String, String>{};
  existing.forEach((tileKey, buyerId) {
    final provinceId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceId != conqueredProvinceId) {
      filtered[tileKey] = buyerId;
    } else {
      removed++;
    }
  });
  onRemoved(removed);
  return filtered;
}

/// Counts Spy reveal timer entries cleared for [provinceId] for old and/or new
/// owner (one count per owner map that contains the province key).
int countSpyTimersClearedForProvinceOwnershipTransfer(
  Map<String, Map<String, int>> spyRevealTurnsByPlayer,
  String provinceId,
  String oldOwnerId,
  String newOwnerId,
) {
  var n = 0;
  final oldMap = spyRevealTurnsByPlayer[oldOwnerId];
  if (oldMap != null && oldMap.containsKey(provinceId)) {
    n++;
  }
  final newMap = spyRevealTurnsByPlayer[newOwnerId];
  if (newMap != null && newMap.containsKey(provinceId)) {
    n++;
  }
  return n;
}

/// Counts civilians that would need relocation in [changedProvinceIds] under
/// current legality (pre-transfer snapshot used for WithResult reporting).
int countIllegalCivilianRelocationsBeforeOwnershipTransfer(
  Game game,
  Set<String> changedProvinceIds,
) {
  var count = 0;
  final factionMembership = DiplomacyFactionMembership.from(game);
  for (final u in game.worldState.allUnitsById.values) {
    if (!changedProvinceIds.contains(u.locationProvinceId)) continue;
    if (canUnitInitiateCombat(u.type) || isShipUnitType(u.type)) continue;
    final tileKey = u.tileKey;
    if (tileKey == null || tileKey.isEmpty) continue;
    if (!civilianMayOccupyLandTileKey(
      game: game,
      playerId: u.ownerId,
      unitType: u.type,
      destinationTileKey: tileKey,
      factionMembership: factionMembership,
    )) {
      count++;
    }
  }
  return count;
}
