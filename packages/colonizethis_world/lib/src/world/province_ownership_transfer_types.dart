import 'package:colonizethis_models/colonizethis_models.dart' show Game;

import 'fog_resolution.dart';

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

/// Empty visibility summary shared by same-owner early-exit paths (Refs #4038).
const ProvinceOwnershipVisibilitySummary
emptyProvinceOwnershipVisibilitySummary = ProvinceOwnershipVisibilitySummary(
  tilesSetFullyVisibleForNewOwner: 0,
  tilesDowngradedForFormerOwner: 0,
);

/// No-op structured result when [oldOwnerId] equals [newOwnerId] (Refs #4038).
CanonicalProvinceOwnershipTransferResult sameOwnerTransferResult({
  required String provinceId,
  required String ownerId,
}) => CanonicalProvinceOwnershipTransferResult(
  provinceId: provinceId,
  oldOwnerId: ownerId,
  newOwnerId: ownerId,
  regimentsTransferred: 0,
  inPortFleetsTransferred: 0,
  purchasedLandEntriesRemoved: 0,
  spyTimersCleared: 0,
  civilianRelocations: 0,
  visibilitySummary: emptyProvinceOwnershipVisibilitySummary,
);
