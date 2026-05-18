import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

/// Invadable Old World frontier held only by Great Powers (no minor on border).
bool isOldWorldGpOnlyInvadableFrontier({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
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

/// Stalled OW expansion with a GP-only invadable frontier (colonial suppression).
bool isStalledOldWorldGpBlockerFocus({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
    isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot);

/// GP owning the most invadable Old World provinces (frontier blocker).
String? primaryInvadableOldWorldGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final provinceOwner = getProvinceOwnerMap(game);
  String? bestGpId;
  var bestCount = 0;
  for (final provinceId in snapshot.conquest.invadableProvinceIdsSorted) {
    final owner = provinceOwner[provinceId];
    if (owner == null || game.playerById(owner) == null) continue;
    var count = 0;
    for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
      if (provinceOwner[pid] == owner) count++;
    }
    if (count > bestCount) {
      bestCount = count;
      bestGpId = owner;
    }
  }
  return bestGpId;
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
