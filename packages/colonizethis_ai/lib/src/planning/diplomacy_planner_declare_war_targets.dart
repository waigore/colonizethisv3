// Declare-war target helpers extracted from `diplomacy_planner.dart` to keep
// each planning file under the 1000 non-comment line cap from
// `SPEC/program/dart-file-non-comment-line-size.md` (Refs #2509).
//
// Each top-level helper computes a single deterministic GP / minor / GP
// blocker declare-war target id for the legacy colonial-pressure ratchet path
// in `runDiplomacyPlannerWithResult`. The phase-planner dispatch path
// (`PhasePlanOutcome`) bypasses these helpers via
// `phase_planner_declare_war_targets.dart` adapters and is unchanged.

import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'army_conquest_prep.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart'
    show addInvadableProvinceMinorOwnersNotAtWar, gpFactionIdsAtWarWith;
import 'planning_imports.dart';

/// First minor nation that owns invadable OW land but is not yet at war, while
/// this GP is below the observer quota and not fighting any Great Power (Refs #2509).
///
/// Also fires during an unwinnable sole-GP war so the GP can pivot to minors.
String? criticalWeakUninvadedMinorDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  final atWarWithGp = gpFactionIdsAtWarWith(game, snapshot);
  if (atWarWithGp.length > 2) {
    return null;
  }
  if (atWarWithGp.length == 2) {
    if (!hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return null;
    }
    for (final factionId in atWarWithGp) {
      if (!isMutualBelowQuotaPlateauPeer(
        ownOw: snapshot.conquest.oldWorldProvincesOwned,
        partnerOw: provinceCountOwnedBy(game, factionId),
      )) {
        return null;
      }
    }
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return null;
  }
  final candidates = <String>{};
  addInvadableProvinceMinorOwnersNotAtWar(
    game: game,
    snapshot: snapshot,
    provinceOwner: getProvinceOwnerMap(game),
    into: candidates,
  );
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

/// Any OW minor not yet at war while stalled below the observer quota (Refs #2509).
String? belowQuotaUninvadedMinorDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      ownOw > kStalledOldWorldProvinceThreshold) {
    return null;
  }
  if (belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot) != null) {
    return null;
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot) &&
      !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
    return null;
  }
  final ownerCache = ProvinceOwnerCache.of(game.worldState);
  final candidates = <String>{
    for (final minor in game.minorNations)
      if (!snapshot.threats.atWarWith.contains(minor.id) &&
          ownerCache.ownsAnyInRegion(minor.id, kRegionOldWorld))
        minor.id,
  };
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

/// Adjacent minor not yet at war while at 8–9 OW with no GP fronts (Refs #2509).
String? plateauOwMinorDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isStalledOldWorldExpansion(ownOw) ||
      !isBelowObserverConquestQuota(ownOw)) {
    return null;
  }
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  if (gpOnlyFrontier &&
      !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
    return null;
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length > 1) {
    for (final factionId in gpWars) {
      if (!isMutualBelowQuotaPlateauPeer(
        ownOw: ownOw,
        partnerOw: provinceCountOwnedBy(game, factionId),
      )) {
        return null;
      }
    }
  } else if (gpWars.length == 1) {
    final partnerOw = provinceCountOwnedBy(game, gpWars.single);
    if (!isMutualBelowQuotaPlateauPeer(ownOw: ownOw, partnerOw: partnerOw) &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return null;
    }
  }
  final candidates = <String>{
    for (final factionId in snapshot.conquest.adjacentOwnerFactionIdsSorted)
      if (isMinorFaction(game, factionId) &&
          !snapshot.threats.atWarWith.contains(factionId))
        factionId,
  };
  if (candidates.isEmpty &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    addInvadableProvinceMinorOwnersNotAtWar(
      game: game,
      snapshot: snapshot,
      provinceOwner: getProvinceOwnerMap(game),
      into: candidates,
    );
  }
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

/// Any OW minor not yet at war while still at default observer start size (seed-42
/// gp4 minor-frontier starvation; Refs #2509).
String? defaultStartOwMinorDeclareTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      ownOw > kObserverDefaultStartOldWorldProvincesPerGp + 1) {
    return null;
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length > 1) {
    return null;
  }
  if (gpWars.length == 1 &&
      !isMutualBelowQuotaPlateauPeer(
        ownOw: ownOw,
        partnerOw: provinceCountOwnedBy(game, gpWars.single),
      ) &&
      !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
    return null;
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot) &&
      !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
    return null;
  }
  final candidates = <String>{};
  if (snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    addInvadableProvinceMinorOwnersNotAtWar(
      game: game,
      snapshot: snapshot,
      provinceOwner: getProvinceOwnerMap(game),
      into: candidates,
    );
  }
  if (candidates.isEmpty) {
    final ownerCache = ProvinceOwnerCache.of(game.worldState);
    for (final minor in game.minorNations) {
      if (snapshot.threats.atWarWith.contains(minor.id)) {
        continue;
      }
      if (ownerCache.ownsAnyInRegion(minor.id, kRegionOldWorld)) {
        candidates.add(minor.id);
      }
    }
  }
  if (candidates.isEmpty) {
    return null;
  }
  final sorted = candidates.toList()..sort();
  return sorted.first;
}

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
