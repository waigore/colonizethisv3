/// EXPAND-phase peace frontier predicates and blocker selectors (Refs #3941).
///
/// Extracted from `expand_phase_planner.dart` so peer-peace deciders and the
/// planner root can share OW frontier helpers without a monolithic `part` tree.
library;

import '../perception/perception_snapshot.dart';
import 'planning_helpers.dart'
    show
        anyInvadableProvinceOwnedByGreatPower,
        anyInvadableProvinceOwnedByMinor,
        gpFactionIdsAtWarWith,
        isOwnOldWorldBelowConquestQuota;
import 'planning_imports.dart';

/// GP owning the most invadable Old World provinces (frontier blocker).
String? primaryInvadableOldWorldGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final invadable = snapshot.conquest.invadableProvinceIdsSorted;
  if (invadable.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final counts = <String, int>{};
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null || game.playerById(owner) == null) continue;
    counts[owner] = (counts[owner] ?? 0) + 1;
  }
  if (counts.isEmpty) {
    return null;
  }
  String? bestGpId;
  var bestCount = 0;
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null) continue;
    final count = counts[owner];
    if (count == null) continue;
    if (count > bestCount) {
      bestCount = count;
      bestGpId = owner;
    }
  }
  return bestGpId;
}

/// True when every invadable OW province is owned by a Great Power.
bool isOldWorldGpOnlyInvadableFrontier({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return false;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
  );
  if (minorsOwnInvadable) {
    return false;
  }
  return anyInvadableProvinceOwnedByGreatPower(
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
  );
}

/// True when an Old World minor still holds land and is not at war with us.
bool hasUninvadedOldWorldMinor({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownerCache = ProvinceOwnerCache.of(game.worldState);
  for (final minor in game.minorNations) {
    if (snapshot.threats.atWarWith.contains(minor.id)) {
      continue;
    }
    if (ownerCache.ownsAnyInRegion(minor.id, kRegionOldWorld)) {
      return true;
    }
  }
  return false;
}

/// True when any minor still owns at least one Old World province.
bool anyMinorOwnsOldWorldProvince(Game game) {
  final ownerCache = ProvinceOwnerCache.of(game.worldState);
  return game.minorNations.any(
    (m) => ownerCache.ownsAnyInRegion(m.id, kRegionOldWorld),
  );
}

/// Sole at-war Great Power id, or `null` when the GP-war set is not length one.
String? soleAtWarGreatPowerId({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length != 1) {
    return null;
  }
  return gpWars.single;
}

/// Both sides stalled below quota within one OW province of each other.
bool isMutualBelowQuotaPlateauPeer({
  required int ownOw,
  required int partnerOw,
}) =>
    isStalledOldWorldExpansion(ownOw) &&
    isStalledOldWorldExpansion(partnerOw) &&
    isBelowObserverConquestQuota(ownOw) &&
    isBelowObserverConquestQuota(partnerOw) &&
    (partnerOw - ownOw).abs() <= 1;

/// Below-quota OW expansion with a GP-only invadable frontier.
bool isStalledOldWorldGpBlockerFocus({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    isOwnOldWorldBelowConquestQuota(snapshot) &&
    isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot);

/// Whether the active player is in a geographic peer-war lock against
/// [peerGpId] — exactly one Great Power foe owns every Old World province
/// adjacent to the active player's territory (Refs #2847 § H4-a).
bool expandIsGeographicPeerWarLock({
  required AIWorldSnapshot snapshot,
  required String peerGpId,
}) {
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
  if (adjacentOwners.length != 1) {
    return false;
  }
  return adjacentOwners.single == peerGpId;
}

/// Whether [planExpandEconomy] should widen the insufficient-regiment
/// force-build arm (Arm D) under the EXPAND-trap (Refs #2847 § H3).
bool expandIsGeographicPeerWarLockNoNwTreasuryRecovery({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.colonial.newWorldProvincesOwned > 0) {
    return false;
  }
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
  if (adjacentOwners.length != 1) {
    return false;
  }
  final peerGpId = adjacentOwners.single;
  if (game.playerById(peerGpId) == null) {
    return false;
  }
  return expandIsGeographicPeerWarLock(snapshot: snapshot, peerGpId: peerGpId);
}
