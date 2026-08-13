// GP-blocker declare-war target helpers (Refs #2509; #4365 Slice A).

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'expand_phase_planner.dart';
import 'planning_imports.dart';

/// Declare on an invadable OW Great Power while stalled below the observer quota.
String? stalledInvadableGpOwnerDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isStalledOldWorldExpansion(ownOw) ||
      !isBelowObserverConquestQuota(ownOw)) {
    return null;
  }
  if (hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
    return null;
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final candidates = <String>{};
  for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
    final owner = provinceOwner[pid];
    if (owner == null || game.playerById(owner) == null) {
      continue;
    }
    if (snapshot.threats.atWarWith.contains(owner)) {
      continue;
    }
    final partnerOw = provinceCountOwnedBy(game, owner);
    if (isMutualBelowQuotaPlateauPeer(ownOw: ownOw, partnerOw: partnerOw)) {
      final blocker = primaryInvadableOldWorldGpBlocker(
        game: game,
        snapshot: snapshot,
      );
      if (owner != blocker) {
        continue;
      }
      if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot) &&
          (partnerOw - ownOw).abs() <= 1 &&
          regimentCountForPlayer(game, snapshot.playerId) > 0 &&
          regimentCountForPlayer(game, owner) > 0 &&
          !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
        continue;
      }
    }
    candidates.add(owner);
  }
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

/// Declare war on the GP frontier blocker when invadable OW is GP-held only.
String? stalledGpBlockerDeclareWarTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (regimentCountForPlayer(game, snapshot.playerId) == 0) {
    return null;
  }
  if (!isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return null;
  }
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
      !isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null ||
      snapshot.threats.atWarWith.contains(blocker) ||
      snapshot.relations[blocker]?.atWar == true) {
    return null;
  }
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  final blockerOw = provinceCountOwnedBy(game, blocker);
  if (isMutualBelowQuotaPlateauPeer(ownOw: ownOw, partnerOw: blockerOw)) {
    if (regimentCountForPlayer(game, blocker) == 0) {
      return null;
    }
    if (snapshot.threats.atWarWith.contains(blocker) ||
        snapshot.relations[blocker]?.atWar == true) {
      return null;
    }
    if (ownOw > blockerOw ||
        (ownOw == blockerOw && snapshot.playerId.compareTo(blocker) > 0)) {
      return null;
    }
  }
  if (unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot) ==
      blocker) {
    return null;
  }
  final turn = game.worldState.turnState.turnNumber;
  if (turn <= kDeclareWarEarlyAntiDogpileMaxTurn &&
      isBelowObserverConquestQuota(provinceCountOwnedBy(game, blocker)) &&
      !isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return null;
  }
  return blocker;
}
