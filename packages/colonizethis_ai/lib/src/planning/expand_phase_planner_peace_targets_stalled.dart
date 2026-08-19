/// Stalled / unwinnable / consolidate EXPAND peace targets (Refs #4079 Slice C).
library;

import '../perception/perception_snapshot.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

/// At-war minor that owns the most invadable OW provinces, or `null`.
String? stalledFocusMinorTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final provinceOwner = getProvinceOwnerMap(game);
  String? bestMinorId;
  var bestInvadableCount = 0;
  for (final minor in game.minorNations) {
    final rel = getRelation(game, snapshot.playerId, minor.id);
    if (rel?.state != RelationState.atWar) continue;
    final invadableCount = snapshot.conquest.invadableProvinceIdsSorted
        .where((pid) => provinceOwner[pid] == minor.id)
        .length;
    if (invadableCount > bestInvadableCount) {
      bestInvadableCount = invadableCount;
      bestMinorId = minor.id;
    }
  }
  return bestMinorId;
}

/// Whether peacing a sole-GP war still leaves a minor OW pivot.
///
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting.
bool canPivotFromSoleGpWarAfterPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.oldWorldProvincesOwned >=
      kObserverConquestMinOwProvincesPerGp) {
    return true;
  }
  final minorsOnMap = anyMinorOwnsOldWorldProvince(game);
  if (minorsOnMap) {
    return true;
  }
  // Route the minor-owned invadable-frontier scan through the shared
  // [anyInvadableProvinceOwnedByMinor] helper (Refs #3717 expand-peace
  // scoring-skeleton dedup), matching the sibling EXPAND-peace deciders. The
  // owner map is resolved once here instead of per invadable province, removing
  // the prior per-iteration `getProvinceOwnerMap(game)` rebuild while keeping
  // byte-identical results (`isMinorFaction` over the same owner map and
  // [ConquestSummary.invadableProvinceIdsSorted] short-circuit).
  return anyInvadableProvinceOwnedByMinor(
    game: game,
    snapshot: snapshot,
    provinceOwner: getProvinceOwnerMap(game),
  );
}

/// Peace the lone GP foe when the war is unwinnable and a minor pivot remains.
String? unwinnableSoleGpFrontierPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final enemy = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  if (enemy == null) {
    return null;
  }
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return null;
  }
  if (!canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot)) {
    return null;
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  final enemyOw = provinceCountOwnedBy(game, enemy);
  final minDeficit = own <= kObserverDefaultStartOldWorldProvincesPerGp
      ? 1
      : own >= kObserverConquestMinOwProvincesPerGp - 2 &&
            !isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)
      ? 1
      : kUnwinnableSoleGpMinProvinceDeficit;
  if (enemyOw < own + minDeficit) {
    return null;
  }
  return enemy;
}

/// Peace the lone GP foe to lock observer gains once the OW buffer is secure.
String? consolidateGainsSoleGpPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final enemy = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  if (enemy == null) {
    return null;
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  if (own < kObserverConquestConsolidateMinOwProvinces) {
    return null;
  }
  final enemyOw = provinceCountOwnedBy(game, enemy);
  if (own < enemyOw + kConsolidateGainsSoleGpProvinceLead) {
    return null;
  }
  return enemy;
}
