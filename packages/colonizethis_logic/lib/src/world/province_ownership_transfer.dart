import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import 'army_migration.dart';
import 'civilian_tile_occupancy.dart';
import 'civilian_ownership_legality.dart';
import 'fog_resolution.dart';
import 'province_lookup.dart';
import 'unit_lookup.dart';

/// Structured result of a single canonical province ownership transfer.
/// SPEC GitHub #2026 / SPEC/program/fog-and-exploration-resolution.md.
class CanonicalProvinceOwnershipTransferResult {
  const CanonicalProvinceOwnershipTransferResult({
    required this.provinceId,
    required this.oldOwnerId,
    required this.newOwnerId,
    required this.regimentsTransferred,
    required this.inPortFleetsTransferred,
    required this.purchasedLandEntriesRemoved,
    required this.spyTimersCleared,
    required this.civilianRelocations,
    required this.visibilitySummary,
  });

  final String provinceId;
  final String oldOwnerId;
  final String newOwnerId;
  final int regimentsTransferred;
  final int inPortFleetsTransferred;
  final int purchasedLandEntriesRemoved;
  final int spyTimersCleared;
  final int civilianRelocations;
  final ProvinceOwnershipVisibilitySummary visibilitySummary;
}

/// Aggregated results from [applyBulkCanonicalProvinceOwnershipTransfers].
class BulkProvinceOwnershipTransferResult {
  const BulkProvinceOwnershipTransferResult({
    required this.game,
    required this.perProvince,
  });

  final Game game;
  final List<CanonicalProvinceOwnershipTransferResult> perProvince;
}

Map<String, String> _clearPurchasedTilesForProvince(
  WorldState worldState,
  String conqueredProvinceId,
  void Function(int removed) onRemoved,
) {
  final existing = worldState.purchasedTilesByTileKey;
  if (existing.isEmpty) return existing;

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

int _countPurchasedTilesForProvince(
  WorldState worldState,
  String conqueredProvinceId,
) {
  final existing = worldState.purchasedTilesByTileKey;
  if (existing.isEmpty) {
    return 0;
  }
  var removed = 0;
  for (final tileKey in existing.keys) {
    final provinceId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceId == conqueredProvinceId) {
      removed++;
    }
  }
  return removed;
}

int _spyTimerRemovalsForProvince(
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

int _civilianRelocationCountBefore(Game game, Set<String> changedProvinceIds) {
  var count = 0;
  final factionMembership = DiplomacyFactionMembership.from(game);
  for (final u in allUnitsFromWorld(game.worldState)) {
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

typedef _CanonicalProvinceTransferRow = ({
  Province province,
  String canonicalProvinceId,
});

typedef _CanonicalProvinceTransferContext = ({
  _CanonicalProvinceTransferRow row,
  RegionData region,
  int provinceIndex,
});

_CanonicalProvinceTransferContext _resolveValidatedCanonicalTransfer(
  Game game, {
  required String targetProvinceId,
  required String oldOwnerId,
  required String newOwnerId,
}) {
  final rowNullable = resolveProvinceRowForOwnershipTransfer(
    game.worldState,
    targetProvinceId,
  );
  if (rowNullable == null) {
    throw StateError(
      'Canonical province transfer: province not found: $targetProvinceId',
    );
  }
  final row = rowNullable;
  if (row.province.ownerId != oldOwnerId) {
    throw StateError(
      'Canonical province transfer: expected owner $oldOwnerId for '
      '$targetProvinceId, found ${row.province.ownerId}',
    );
  }

  final canonicalId = row.canonicalProvinceId;
  final regionId = row.province.regionId;
  final region = regionDataForId(game.worldState, regionId);
  if (region == null) {
    throw StateError(
      'Canonical province transfer: region not found for province '
      '$canonicalId (regionId=$regionId)',
    );
  }
  final provinceIndex = provinceListIndexOfProvinceId(
    region.provinces,
    canonicalId,
  );
  if (provinceIndex == null) {
    throw StateError(
      'Canonical province transfer: province missing from region data '
      '$canonicalId',
    );
  }
  return (row: row, region: region, provinceIndex: provinceIndex);
}

/// Single-province canonical ownership transfer: province owner, resident
/// military regiments, in-port fleets, purchased land, Spy timers, civilian
/// legality, and immediate visibility updates.
///
/// [targetProvinceId] is normally a prefixed province id (`regionId|localId`);
/// When [relocateIllegalCivilians] is false, skips per-transfer civilian
/// legality normalization (used by diplomacy bulk absorption, which remaps
/// unit ownership first then runs one relocation pass).
Game applyCanonicalSingleProvinceOwnershipTransfer(
  Game game, {
  required String targetProvinceId,
  required String oldOwnerId,
  required String newOwnerId,
  bool relocateIllegalCivilians = true,
}) {
  return _applyCanonicalSingleProvinceOwnershipTransferCore(
    game,
    targetProvinceId: targetProvinceId,
    oldOwnerId: oldOwnerId,
    newOwnerId: newOwnerId,
    relocateIllegalCivilians: relocateIllegalCivilians,
  ).game;
}

({Game game, ProvinceOwnershipVisibilitySummary visibilitySummary})
_applyCanonicalSingleProvinceOwnershipTransferFromResolved(
  Game game, {
  required String targetProvinceId,
  required String oldOwnerId,
  required String newOwnerId,
  required _CanonicalProvinceTransferContext ctx,
  bool relocateIllegalCivilians = true,
}) {
  final region = ctx.region;
  final pIdx = ctx.provinceIndex;
  final canonicalId = ctx.row.canonicalProvinceId;
  final regionId = ctx.row.province.regionId;

  final updatedProvinces = List<Province>.from(region.provinces)
    ..[pIdx] = region.provinces[pIdx].copyWith(ownerId: newOwnerId);

  final updatedUnits = region.units.map((u) {
    if ((u.locationProvinceId == targetProvinceId ||
            u.locationProvinceId == canonicalId) &&
        u.ownerId == oldOwnerId &&
        isMilitaryUnit(u.type)) {
      return u.copyWith(ownerId: newOwnerId);
    }
    return u;
  }).toList();

  final updatedFleets = game.worldState.fleets.map((f) {
    final inPort = f.inPortAtProvinceId;
    if ((inPort == targetProvinceId || inPort == canonicalId) &&
        f.ownerId == oldOwnerId) {
      return f.copyWith(ownerId: newOwnerId);
    }
    return f;
  }).toList();

  final purchasedAfter = _clearPurchasedTilesForProvince(
    game.worldState,
    canonicalId,
    (_) {},
  );

  final spyNext = clearSpyRevealTimersForProvinceOwnershipTransfer(
    game.worldState.spyRevealTurnsByPlayer,
    canonicalId,
    oldOwnerId,
    newOwnerId,
  );

  final newRegion = RegionData(
    provinces: updatedProvinces,
    units: updatedUnits,
  );

  var nextWs = game.worldState.copyWith(
    fleets: updatedFleets,
    purchasedTilesByTileKey: purchasedAfter,
    spyRevealTurnsByPlayer: spyNext,
  );
  nextWs = nextWs.updateRegionById(regionId, (_) => newRegion);

  var nextGame = game.copyWith(worldState: nextWs);

  final visOutcome = applyProvinceOwnershipChangeVisibility(
    nextGame,
    canonicalId,
    oldOwnerId,
    newOwnerId,
  );
  nextGame = visOutcome.game;

  if (relocateIllegalCivilians) {
    nextGame = relocateIllegalCiviliansInChangedProvinces(
      nextGame,
      changedProvinceIds: {canonicalId},
    );
  }

  nextGame = nextGame.copyWith(
    worldState: reconcileArmiesAfterUnitsChanged(nextGame.worldState, nextGame),
  );

  return (game: nextGame, visibilitySummary: visOutcome.visibilitySummary);
}

({Game game, ProvinceOwnershipVisibilitySummary visibilitySummary})
_applyCanonicalSingleProvinceOwnershipTransferCore(
  Game game, {
  required String targetProvinceId,
  required String oldOwnerId,
  required String newOwnerId,
  bool relocateIllegalCivilians = true,
}) {
  if (oldOwnerId == newOwnerId) {
    return (
      game: game,
      visibilitySummary: const ProvinceOwnershipVisibilitySummary(
        tilesSetFullyVisibleForNewOwner: 0,
        tilesDowngradedForFormerOwner: 0,
      ),
    );
  }

  final ctx = _resolveValidatedCanonicalTransfer(
    game,
    targetProvinceId: targetProvinceId,
    oldOwnerId: oldOwnerId,
    newOwnerId: newOwnerId,
  );
  return _applyCanonicalSingleProvinceOwnershipTransferFromResolved(
    game,
    targetProvinceId: targetProvinceId,
    oldOwnerId: oldOwnerId,
    newOwnerId: newOwnerId,
    ctx: ctx,
    relocateIllegalCivilians: relocateIllegalCivilians,
  );
}

/// Same transfer as [applyCanonicalSingleProvinceOwnershipTransfer] with a
/// structured result payload for reporting.
({Game game, CanonicalProvinceOwnershipTransferResult result})
applyCanonicalSingleProvinceOwnershipTransferWithResult(
  Game game, {
  required String targetProvinceId,
  required String oldOwnerId,
  required String newOwnerId,
  bool relocateIllegalCivilians = true,
}) {
  if (oldOwnerId == newOwnerId) {
    return (
      game: game,
      result: CanonicalProvinceOwnershipTransferResult(
        provinceId: targetProvinceId,
        oldOwnerId: oldOwnerId,
        newOwnerId: newOwnerId,
        regimentsTransferred: 0,
        inPortFleetsTransferred: 0,
        purchasedLandEntriesRemoved: 0,
        spyTimersCleared: 0,
        civilianRelocations: 0,
        visibilitySummary: const ProvinceOwnershipVisibilitySummary(
          tilesSetFullyVisibleForNewOwner: 0,
          tilesDowngradedForFormerOwner: 0,
        ),
      ),
    );
  }

  final ctx = _resolveValidatedCanonicalTransfer(
    game,
    targetProvinceId: targetProvinceId,
    oldOwnerId: oldOwnerId,
    newOwnerId: newOwnerId,
  );
  final row = ctx.row;
  final region = ctx.region;
  final canonicalId = row.canonicalProvinceId;

  var regimentsTransferred = 0;
  for (final u in region.units) {
    if ((u.locationProvinceId == targetProvinceId ||
            u.locationProvinceId == canonicalId) &&
        u.ownerId == oldOwnerId &&
        isMilitaryUnit(u.type)) {
      regimentsTransferred++;
    }
  }

  var inPortFleetsTransferred = 0;
  for (final f in game.worldState.fleets) {
    final inPort = f.inPortAtProvinceId;
    if ((inPort == targetProvinceId || inPort == canonicalId) &&
        f.ownerId == oldOwnerId) {
      inPortFleetsTransferred++;
    }
  }

  final purchasedLandEntriesRemoved = _countPurchasedTilesForProvince(
    game.worldState,
    canonicalId,
  );

  final spyTimersCleared = _spyTimerRemovalsForProvince(
    game.worldState.spyRevealTurnsByPlayer,
    canonicalId,
    oldOwnerId,
    newOwnerId,
  );

  final civilianRelocations = _civilianRelocationCountBefore(game, {
    targetProvinceId,
    canonicalId,
  });

  final core = _applyCanonicalSingleProvinceOwnershipTransferFromResolved(
    game,
    targetProvinceId: targetProvinceId,
    oldOwnerId: oldOwnerId,
    newOwnerId: newOwnerId,
    ctx: ctx,
    relocateIllegalCivilians: relocateIllegalCivilians,
  );

  return (
    game: core.game,
    result: CanonicalProvinceOwnershipTransferResult(
      provinceId: targetProvinceId,
      oldOwnerId: oldOwnerId,
      newOwnerId: newOwnerId,
      regimentsTransferred: regimentsTransferred,
      inPortFleetsTransferred: inPortFleetsTransferred,
      purchasedLandEntriesRemoved: purchasedLandEntriesRemoved,
      spyTimersCleared: spyTimersCleared,
      civilianRelocations: civilianRelocations,
      visibilitySummary: core.visibilitySummary,
    ),
  );
}

/// Invokes canonical single-province transfer once per id in order; aborts on
/// first failure without processing remaining ids.
///
/// Set [relocateIllegalCivilians] to false when callers will remap unit
/// ownership globally after the bulk step (e.g. Join Empire), then run
/// [relocateIllegalCiviliansInChangedProvinces] once for all provinces.
BulkProvinceOwnershipTransferResult
applyBulkCanonicalProvinceOwnershipTransfers(
  Game game, {
  required List<String> provinceIdsInOrder,
  required String oldOwnerId,
  required String newOwnerId,
  bool relocateIllegalCivilians = true,
}) {
  final results = <CanonicalProvinceOwnershipTransferResult>[];
  var current = game;
  for (final pid in provinceIdsInOrder) {
    final out = applyCanonicalSingleProvinceOwnershipTransferWithResult(
      current,
      targetProvinceId: pid,
      oldOwnerId: oldOwnerId,
      newOwnerId: newOwnerId,
      relocateIllegalCivilians: relocateIllegalCivilians,
    );
    current = out.game;
    results.add(out.result);
  }
  return BulkProvinceOwnershipTransferResult(
    game: current,
    perProvince: results,
  );
}
