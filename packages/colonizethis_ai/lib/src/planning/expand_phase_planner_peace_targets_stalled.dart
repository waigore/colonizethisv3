/// Stalled / unwinnable / consolidate EXPAND peace targets (Refs #4079 Slice C).
library;

import '../perception/perception_snapshot.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';


/// focus minor), or `null` when no at-war minor owns any invadable OW
/// province.
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

/// Whether peacing a below-quota sole-GP war leaves the EXPAND-phase
/// player a pivot path back to active OW expansion (a remaining
/// uninvaded minor or a minor-owned invadable frontier province).
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `canPivotFromSoleGpWarAfterPeace` predicate previously hosted in
/// `colonial_pressure.dart`. Used by [unwinnableSoleGpFrontierPeaceTarget]
/// in `colonial_pressure.dart` to gate the "peace the lone GP foe when
/// clearly outgunned" decision — peacing is only worthwhile if the
/// active GP can immediately resume EXPAND against a minor rather than
/// idle while the lone GP rebuilds.
///
/// Returns `true` exactly when **any** of these hold:
///   1. The active player is at or above
///      [kObserverConquestMinOwProvincesPerGp] OW provinces (no longer
///      in EXPAND territory; the EXPAND-trap pivot guard is irrelevant
///      so we always allow peace).
///   2. A minor nation still owns at least one Old World province
///      anywhere on the map (the GP can attempt to formalize a new
///      minor war after peacing).
///   3. The active player's [ConquestSummary.invadableProvinceIdsSorted]
///      contains a province whose current owner is a minor nation (the
///      planner can immediately declare on that minor after peacing
///      the lone GP, since the invadable frontier already has a minor
///      pivot).
///
/// All three arms are short-circuited (`||` semantics): the function
/// returns on the first true arm without walking the remaining checks.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_can_pivot_from_sole_gp_war_branches_test.dart`
/// fixture and the existing `unwinnableSoleGpFrontierPeaceTarget` caller
/// within `colonial_pressure.dart` itself) so the now-completed S1 deletion of
/// that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in the smaller of
/// [WorldState.oldWorld] provinces (minors-on-map scan) and
/// [ConquestSummary.invadableProvinceIdsSorted] (minor-owned invadable
/// scan); short-circuited at the quota arm when above quota.
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

/// Returns the lone Great Power foe's `factionId` when an EXPAND-phase
/// player should peace it as unwinnable, or `null` when the forced
/// sole-GP-frontier peace path does not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `unwinnableSoleGpFrontierPeaceTarget` peace decider previously hosted
/// in `colonial_pressure.dart`. The decider is the below-quota EXPAND
/// shortcut that surrenders an unwinnable sole-GP war so the planner
/// can pivot back to a minor frontier; it composes the already-canonical
/// helpers [soleAtWarGreatPowerId] and [canPivotFromSoleGpWarAfterPeace]
/// with the deficit-band table from `SPEC/ai/ai-architecture.md`
/// § Diplomacy targeting — "Forced offerPeace toward the sole at-war
/// Great Power...".
///
/// Returns `null` for any of the following short-circuits (in order):
///   1. [soleAtWarGreatPowerId] returns `null` — no sole GP foe (zero
///      GP wars after the [Game.playerById] filter, or two or more GP
///      wars). Multi-front peace selection (`nearQuotaHoldPeaceTargets`,
///      `belowQuotaPeerGpPeaceTargets`) owns the decision in that
///      shape, not this shortcut.
///   2. [isBelowObserverConquestQuota] is `false` for the active
///      player's [ConquestSummary.oldWorldProvincesOwned] — at or
///      above the observer OW quota the consolidate-gains decider
///      ([consolidateGainsSoleGpPeaceTarget]) and the quota-met
///      futile-peace collectors take over.
///   3. [canPivotFromSoleGpWarAfterPeace] is `false` — peacing the
///      lone GP would leave no SPEC-legal minor pivot, so the planner
///      must keep the war open and defer to the critical-weak survival
///      peace path instead.
///   4. The OW lead deficit `enemyOw - ownOw` is strictly less than the
///      band's `minDeficit`:
///        * `kUnwinnableSoleGpMinProvinceDeficit` (today: 2) on the
///          8–9 OW GP-only invadable frontier band — preserves
///          near-quota GP-only wars when the partner only narrowly
///          leads (lead 1) so the planner does not surrender the
///          near-peer blocker;
///        * `1` everywhere else (default-start band `own ≤
///          kObserverDefaultStartOldWorldProvincesPerGp`; 8–9 OW
///          non-GP-only band) — minimum +1 OW lead suffices.
///
/// When all four gates pass, returns the [soleAtWarGreatPowerId] result
/// (the sole GP foe).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `diplomacy_planner_peace_targets.dart` consumer chain
/// and the
/// `colonial_pressure_unwinnable_sole_gp_branches_test.dart` fixture)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in
/// [ConquestSummary.invadableProvinceIdsSorted] via the GP-only-frontier
/// composite; constant-time on all other arms (short-circuited by the
/// sole-GP and quota guards above the band table).
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

/// Returns the lone Great Power foe's `factionId` when a quota-met
/// EXPAND/COLONIAL player should peace it to lock in observer gains,
/// or `null` when the consolidate-gains shortcut does not apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `consolidateGainsSoleGpPeaceTarget` peace decider previously hosted
/// in `colonial_pressure.dart`. The decider is the quota-met companion
/// of [unwinnableSoleGpFrontierPeaceTarget]: once the active player has
/// secured a comfortable OW buffer above the observer quota and leads
/// the lone GP enemy by at least
/// [kConsolidateGainsSoleGpProvinceLead] OW provinces, peacing locks
/// the conquest gains in before a counter-offensive can erase them
/// (`SPEC/ai/ai-architecture.md` § Diplomacy targeting —
/// "when this GP holds at least
/// `kObserverConquestConsolidateMinOwProvinces` and leads the sole
/// enemy by `kConsolidateGainsSoleGpProvinceLead` or more (lock
/// observer gains before a counter-offensive)").
///
/// Returns `null` for any of the following short-circuits (in order):
///   1. [soleAtWarGreatPowerId] returns `null` — no sole GP foe (zero
///      or two-plus GP wars). The consolidate shortcut is sole-GP-only
///      so a multi-front context defers to the standard collectors.
///   2. [ConquestSummary.oldWorldProvincesOwned] is strictly below
///      [kObserverConquestConsolidateMinOwProvinces] — the active
///      player has not yet built the OW buffer SPEC requires before
///      locking in via peace (otherwise a marginal lead could be
///      reversed before the consolidate decision pays off).
///   3. The OW lead `own - enemyOw` is strictly below
///      [kConsolidateGainsSoleGpProvinceLead] — the consolidate
///      shortcut requires a clear lead, not just any positive gap.
///
/// When all three gates pass, returns the [soleAtWarGreatPowerId]
/// result (the sole GP foe).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the
/// `colonial_pressure_consolidate_gains_sole_gp_peace_branches_test.dart`
/// fixture and the
/// `diplomatic_candidate_scoring_offer_peace.dart` consumer chain) so
/// the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in the total province
/// count via [provinceCountOwnedBy] for the enemy lookup; otherwise
/// constant-time.
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
