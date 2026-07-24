import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'army_migration.dart';
import 'civilian_ownership_legality.dart';
import 'fog_resolution.dart';
import 'game_world_mutations.dart';
import 'province_lookup.dart';
import 'province_ownership_transfer_stages.dart';
import 'province_ownership_transfer_types.dart';

typedef CanonicalProvinceTransferContext = ({
  Province province,
  String canonicalProvinceId,
  RegionData region,
  int provinceIndex,
});

typedef CanonicalProvinceTransferOutcome = ({
  Game game,
  ProvinceOwnershipVisibilitySummary visibilitySummary,
  int regimentsTransferred,
  int inPortFleetsTransferred,
  int purchasedLandEntriesRemoved,
  int spyTimersCleared,
});

CanonicalProvinceTransferContext resolveValidatedCanonicalTransfer(
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
  return (
    province: row.province,
    canonicalProvinceId: canonicalId,
    region: region,
    provinceIndex: provinceIndex,
  );
}

CanonicalProvinceTransferOutcome
applyCanonicalSingleProvinceOwnershipTransferFromResolved(
  Game game, {
  required String targetProvinceId,
  required String oldOwnerId,
  required String newOwnerId,
  required CanonicalProvinceTransferContext ctx,
  bool relocateIllegalCivilians = true,
}) {
  final region = ctx.region;
  final pIdx = ctx.provinceIndex;
  final canonicalId = ctx.canonicalProvinceId;
  final regionId = ctx.province.regionId;

  final updatedProvinces = List<Province>.from(region.provinces)
    ..[pIdx] = region.provinces[pIdx].copyWith(ownerId: newOwnerId);

  var regimentsTransferred = 0;
  final updatedUnits = region.units.map((u) {
    if ((u.locationProvinceId == targetProvinceId ||
            u.locationProvinceId == canonicalId) &&
        u.ownerId == oldOwnerId &&
        isMilitaryUnit(u.type)) {
      regimentsTransferred++;
      return u.copyWith(ownerId: newOwnerId);
    }
    return u;
  }).toList();

  var inPortFleetsTransferred = 0;
  final updatedFleets = game.worldState.fleets.map((f) {
    final inPort = f.inPortAtProvinceId;
    if ((inPort == targetProvinceId || inPort == canonicalId) &&
        f.ownerId == oldOwnerId) {
      inPortFleetsTransferred++;
      return f.copyWith(ownerId: newOwnerId);
    }
    return f;
  }).toList();

  var purchasedLandEntriesRemoved = 0;
  final purchasedAfter = clearPurchasedTilesForProvinceOwnershipTransfer(
    game.worldState,
    canonicalId,
    (removed) => purchasedLandEntriesRemoved = removed,
  );

  final spyTimersCleared = countSpyTimersClearedForProvinceOwnershipTransfer(
    game.worldState.spyRevealTurnsByPlayer,
    canonicalId,
    oldOwnerId,
    newOwnerId,
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

  var nextGame = game.withWorldState(nextWs);

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

  return (
    game: nextGame,
    visibilitySummary: visOutcome.visibilitySummary,
    regimentsTransferred: regimentsTransferred,
    inPortFleetsTransferred: inPortFleetsTransferred,
    purchasedLandEntriesRemoved: purchasedLandEntriesRemoved,
    spyTimersCleared: spyTimersCleared,
  );
}

({Game game, ProvinceOwnershipVisibilitySummary visibilitySummary})
applyCanonicalSingleProvinceOwnershipTransferCore(
  Game game, {
  required String targetProvinceId,
  required String oldOwnerId,
  required String newOwnerId,
  bool relocateIllegalCivilians = true,
}) {
  if (oldOwnerId == newOwnerId) {
    return (
      game: game,
      visibilitySummary: emptyProvinceOwnershipVisibilitySummary,
    );
  }

  final ctx = resolveValidatedCanonicalTransfer(
    game,
    targetProvinceId: targetProvinceId,
    oldOwnerId: oldOwnerId,
    newOwnerId: newOwnerId,
  );
  final outcome = applyCanonicalSingleProvinceOwnershipTransferFromResolved(
    game,
    targetProvinceId: targetProvinceId,
    oldOwnerId: oldOwnerId,
    newOwnerId: newOwnerId,
    ctx: ctx,
    relocateIllegalCivilians: relocateIllegalCivilians,
  );
  return (
    game: outcome.game,
    visibilitySummary: outcome.visibilitySummary,
  );
}
