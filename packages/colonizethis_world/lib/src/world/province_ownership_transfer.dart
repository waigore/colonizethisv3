import 'package:colonizethis_models/colonizethis_models.dart';

export 'province_ownership_transfer_types.dart'
    show
        BulkProvinceOwnershipTransferResult,
        CanonicalProvinceOwnershipTransferResult;

import 'province_ownership_transfer_core.dart';
import 'province_ownership_transfer_stages.dart';
import 'province_ownership_transfer_types.dart';

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
  return applyCanonicalSingleProvinceOwnershipTransferCore(
    game,
    targetProvinceId: targetProvinceId,
    oldOwnerId: oldOwnerId,
    newOwnerId: newOwnerId,
    relocateIllegalCivilians: relocateIllegalCivilians,
  ).game;
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
      result: sameOwnerTransferResult(
        provinceId: targetProvinceId,
        ownerId: oldOwnerId,
      ),
    );
  }

  final ctx = resolveValidatedCanonicalTransfer(
    game,
    targetProvinceId: targetProvinceId,
    oldOwnerId: oldOwnerId,
    newOwnerId: newOwnerId,
  );
  final canonicalId = ctx.canonicalProvinceId;

  final civilianRelocations =
      countIllegalCivilianRelocationsBeforeOwnershipTransfer(game, {
    targetProvinceId,
    canonicalId,
  });

  final core = applyCanonicalSingleProvinceOwnershipTransferFromResolved(
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
      regimentsTransferred: core.regimentsTransferred,
      inPortFleetsTransferred: core.inPortFleetsTransferred,
      purchasedLandEntriesRemoved: core.purchasedLandEntriesRemoved,
      spyTimersCleared: core.spyTimersCleared,
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
