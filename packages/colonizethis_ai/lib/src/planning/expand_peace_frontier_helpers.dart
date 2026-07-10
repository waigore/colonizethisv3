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
///
/// Public entry for the phase dispatcher and orchestrator wiring (Refs
/// #2509 S5). Mirrors the existing `primaryInvadableOldWorldGpBlocker`
/// algorithm in `colonial_pressure.dart` so the new planner stays
/// self-contained against the S1 deletion of that file (Refs #2509 §
/// EXPAND phase planner). Behavior is byte-identical to the legacy helper:
///
///   1. Tally GP ownership across [ConquestSummary.invadableProvinceIdsSorted]
///      using [getProvinceOwnerMap], skipping unowned and non-GP entries.
///   2. Resolve the plurality winner with a second linear pass that
///      preserves the first-iterated-province tiebreak (deterministic
///      against the snapshot's already-sorted invadable list).
///
/// Returns `null` when the invadable list is empty or none of the
/// invadable provinces are owned by a Great Power. Linear in the
/// invadable-OW set, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
String? expandPrimaryInvadableOldWorldGpBlocker({
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

/// Canonical name for [expandPrimaryInvadableOldWorldGpBlocker] (Refs #2509 S1).
String? primaryInvadableOldWorldGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expandPrimaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot);

/// Whether the invadable Old World frontier is held only by Great Powers
/// (no minor nation owns any invadable OW province).
///
/// Mirrors `isOldWorldGpOnlyInvadableFrontier` from `colonial_pressure.dart`.
/// Public entry for the phase dispatcher and orchestrator wiring (Refs
/// #2509 S5). The mutual-plateau sole-GP carve-out in [planExpandPeace]
/// requires this gate so we only peace the lone GP blocker when no minor
/// pivot remains.
bool expandIsOldWorldGpOnlyInvadableFrontier({
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

/// Canonical name for [expandIsOldWorldGpOnlyInvadableFrontier] (Refs #2509 S1).
bool isOldWorldGpOnlyInvadableFrontier({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expandIsOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot);

/// Whether any Old World minor nation still holds provinces and is not
/// already at war with the active player (uninvaded minor pivot remaining).
///
/// The mutual-plateau sole-GP carve-out in [planExpandPeace] holds the GP war
/// while uninvaded minors remain (we should expand against minors first).
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the predicate
/// survives the planned deletion of that file.
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

/// Whether any minor nation still owns at least one Old World province.
///
/// Phase 6b (SPEC/program/worldstate-projection.md slice 8; Refs #3393):
/// replaces the `O(provinces x minors)` nested old-world owner scan
/// (`game.worldState.oldWorld.provinces.any((p) => p.ownerId is a minor id)`)
/// recomputed per EXPAND-phase peace decider with the memoised
/// [ProvinceOwnerCache] via `ownsAnyInRegion(minorId, kRegionOldWorld)`.
/// Behaviour-preserving: "some old-world province is owned by a minor" is
/// logically equal to "some minor owns an old-world province"; minor ids are
/// non-empty, so an empty/`null` owner never equals a minor id.
bool anyMinorOwnsOldWorldProvince(Game game) {
  final ownerCache = ProvinceOwnerCache.of(game.worldState);
  return game.minorNations.any(
    (m) => ownerCache.ownsAnyInRegion(m.id, kRegionOldWorld),
  );
}

/// Returns the `factionId` of the sole Great Power the active player is at
/// war with, or `null` when the at-war set is empty, contains only minor /
/// tribe ids, or contains more than one Great Power.
///
/// Canonical home (Refs #2509 S1) for the legacy `soleAtWarGreatPowerId`
/// predicate previously hosted in `colonial_pressure.dart`. Captures the
/// "exactly one GP foe remaining" precondition shared by the EXPAND-phase
/// sole-GP peace deciders ([unwinnableSoleGpFrontierPeaceTarget],
/// [consolidateGainsSoleGpPeaceTarget]) and the peer-stalled peace
/// helper `belowQuotaPeerGpPeaceTargets` — all of which short-circuit to
/// the default no-peace path when no sole-GP foe is identified.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_sole_at_war_gp_branches_test.dart`
/// fixture, the existing `belowQuotaPeerGpPeaceTargets` /
/// `unwinnableSoleGpFrontierPeaceTarget` / `consolidateGainsSoleGpPeaceTarget`
/// callers within `colonial_pressure.dart` itself) so the planned S1
/// deletion of that file leaves no orphan callers.
///
/// Behavioral invariants pinned at the canonical-home test boundary
/// (`test/planning/expand_phase_planner_sole_gp_war_helpers_test.dart`):
///   1. Empty [ThreatSummary.atWarWith] returns `null` (no foe at all).
///   2. At-war entries that are not current Great Powers
///      ([Game.playerById] returns `null`) are filtered out before the
///      length-one check — pure minor / tribe wars therefore yield
///      `null`.
///   3. The length guard refuses to elect a sole-GP foe when more than
///      one Great Power is at war; a mixed two-GP-plus-minor at-war
///      list still resolves to `null` after the minor filter collapses
///      the list to two GPs.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith].
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

/// Whether [ownOw] and [partnerOw] are both in the stalled below-quota
/// plateau band with similar holdings (within one province of each other).
///
/// Stall threshold ([kStalledOldWorldProvinceThreshold]) and quota
/// ([kObserverConquestMinOwProvincesPerGp]) are authoritative here.
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1).
bool isMutualBelowQuotaPlateauPeer({
  required int ownOw,
  required int partnerOw,
}) =>
    isStalledOldWorldExpansion(ownOw) &&
    isStalledOldWorldExpansion(partnerOw) &&
    isBelowObserverConquestQuota(ownOw) &&
    isBelowObserverConquestQuota(partnerOw) &&
    (partnerOw - ownOw).abs() <= 1;

/// Below-quota OW expansion with a GP-only invadable frontier (seed-42 gp5/gp6).
///
/// Composite gate combining [isBelowObserverConquestQuota] on the active
/// player's [ConquestSummary.oldWorldProvincesOwned] with
/// [isOldWorldGpOnlyInvadableFrontier]: returns `true` only when the GP is
/// strictly below [kObserverConquestMinOwProvincesPerGp] **and** every
/// invadable OW province is owned by a Great Power (no minor pivot
/// remaining on the frontier).
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the predicate
/// survives the planned deletion of that file. Fans out across the
/// EXPAND/COLONIAL goal-scoring and diplomacy-planner call sites
/// (`phase_planner_economy_filter.dart`, `phase_planner_goal_filter.dart`,
/// `diplomacy_planner.dart`, `diplomacy_planner_peace_targets.dart`,
/// `diplomatic_candidate_scoring_*.dart`) that gate the colonial-pressure
/// routing and sole-GP-war scoring on the GP-only-frontier shape.
bool isStalledOldWorldGpBlockerFocus({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    isOwnOldWorldBelowConquestQuota(snapshot) &&
    isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot);
