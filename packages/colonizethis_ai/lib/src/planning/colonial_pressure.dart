import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

/// Stalled OW expansion with every invadable province owned by one Great Power
/// (focus Old World blocker war; suppress NW colonial pressure; Refs #2509).
bool isStalledOldWorldGpBlockerFocus({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return false;
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return false;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) {
      final owner = provinceOwner[pid];
      return owner != null && game.minorNations.any((m) => m.id == owner);
    },
  );
  if (minorsOwnInvadable) {
    return false;
  }
  return snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) => game.playerById(provinceOwner[pid] ?? '') != null,
  );
}

/// Sea-reachable unowned NW provinces or tribe/minor owners still to clear.
bool hasColonialAcquisitionTargets(ColonialSummary colonial) =>
    colonial.invadableNewWorldProvinceIdsSorted.isNotEmpty ||
    colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty;

/// Early expansion boost while the GP holds fewer than
/// [kColonialFewNwProvincesThreshold] NW provinces.
bool isEarlyColonialExpansion(ColonialSummary colonial) =>
    hasColonialAcquisitionTargets(colonial) &&
    colonial.newWorldProvincesOwned < kColonialFewNwProvincesThreshold;

/// When non-null, build-order pass uses `min(buildThreshold, value)`.
int? colonialBuildOrderThresholdCap(ColonialSummary colonial) {
  if (hasColonialAcquisitionTargets(colonial) &&
      colonial.newWorldProvincesOwned > 0) {
    return kColonialBuildOrderThresholdWhenOwnedNwUnderPressure;
  }
  if (colonial.newWorldProvincesOwned > 0) {
    return kColonialBuildOrderThresholdWhenOwnedNw;
  }
  return null;
}
