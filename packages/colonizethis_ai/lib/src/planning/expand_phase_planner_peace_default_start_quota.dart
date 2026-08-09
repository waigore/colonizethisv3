/// Near-quota / below-quota EXPAND peace default-start arms (Refs #4079 Slice C).
library;

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

export 'expand_phase_planner_peace_stalled_pass_predicate.dart'
    show stalledOwExpansionNeedsPeacePass;

import 'expand_phase_planner_gp_blocker_peace.dart';
import 'expand_phase_planner_peace_default_start.dart'
    show defaultStartGpPeaceTargets;
import 'expand_phase_planner_peace_targets.dart';
import 'expand_phase_planner_peer_peace.dart';


/// Returns the deterministic ascending-sorted list of at-war Great
/// Power `factionId`s the active player should `offerPeace` toward
/// at near-quota (8–9 OW) while still below the observer quota in
/// EXPAND, or `const []` when the near-quota hold-gains pivot does
/// not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `nearQuotaHoldPeaceTargets` peace decider previously hosted in
/// `colonial_pressure.dart`. The decider implements the EXPAND-phase
/// "at 8–9 OW, peace distracting GP wars so the planner can hold
/// gains and finish the OW push" pivot for seed-42 gp3 (near-quota
/// stalled-band GP). It composes the canonical helpers
/// [primaryInvadableOldWorldGpBlocker] (frontier blocker selector),
/// [isOldWorldGpOnlyInvadableFrontier] (band selector),
/// [isMutualBelowQuotaPlateauPeer] (sole-GP plateau detector), and
/// [hasUninvadedOldWorldMinor] (minor-pivot detector) with the
/// near-quota band rules from `SPEC/ai/ai-architecture.md`
/// § Diplomacy targeting.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — at or above the
///      observer OW quota the quota-met futile-peace collectors
///      take over.
///   2. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — strictly below
///      the stalled-band threshold the default-start GP-peace
///      collector ([defaultStartGpPeaceTargets]) owns the decision.
///   3. The active player has zero at-war Great Powers in
///      [ThreatSummary.atWarWith] (filtered via [Game.playerById])
///      — no GP wars to peace at all.
///
/// When the guards pass, the function dispatches on the GP-war set:
///   * **Sole GP war arm** — exactly one at-war Great Power. Peaces
///     the lone GP only when the war is a mutual-plateau sole-GP
///     stalemate ([isMutualBelowQuotaPlateauPeer]) on a GP-only
///     invadable frontier ([isOldWorldGpOnlyInvadableFrontier])
///     with no uninvaded OW minors remaining
///     ([hasUninvadedOldWorldMinor] is `false`); otherwise, when
///     the lone GP is the [primaryInvadableOldWorldGpBlocker] and a
///     minor pivot remains the war is held open (`const []`) so the
///     planner keeps fighting the blocker. Every other sole-GP
///     shape falls through to the multi-GP arm below.
///   * **Multi-GP war arm (≥2 at-war GPs, or sole-GP fall-through)**
///     — peace every at-war GP except the
///     [primaryInvadableOldWorldGpBlocker]. Returned in ascending
///     lex order over the GP `factionId`s.
///   * **Sole-GP fall-through** — when the sole-GP arm short-circuit
///     above does not fire and does not return the held-open
///     `const []`, the function falls back to returning the
///     unsorted single-GP list for compatibility with the legacy
///     `colonial_pressure.dart` shape (one element so sort order is
///     trivial).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for
/// legacy callers (the existing `colonial_pressure_test.dart`
/// fixtures that exercise the near-quota arms and the
/// `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` consumer chain) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] across both arms, plus the canonical
/// composite calls into [primaryInvadableOldWorldGpBlocker],
/// [isOldWorldGpOnlyInvadableFrontier],
/// [isMutualBelowQuotaPlateauPeer], and [hasUninvadedOldWorldMinor]
/// (each linear in the OW invadable / minor sets), matching the
/// budget-rule note in `colonizethis-turn-resolution-budget.mdc`
/// (no global province / tile scans introduced by the move).
List<String> nearQuotaHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      !isStalledOldWorldExpansion(ownOw)) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.isEmpty) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  if (gpWars.length == 1) {
    final soleGp = gpWars.single;
    final partnerOw = provinceCountOwnedBy(game, soleGp);
    if (isMutualBelowQuotaPlateauPeer(ownOw: ownOw, partnerOw: partnerOw) &&
        gpOnlyFrontier &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return gpWars;
    }
    if (blocker != null &&
        gpWars.single == blocker &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return const [];
    }
  }
  if (gpWars.length >= 2) {
    return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
  }
  return gpWars;
}

/// At-war minor "active OW front" target while the active player is below
/// the observer OW conquest quota, or `null` when above-quota or no at-war
/// minor owns invadable OW provinces.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `belowQuotaActiveMinorWarTarget` helper previously hosted in
/// `diplomacy_planner_peace_targets.dart`. The helper is a thin
/// below-quota gate over [stalledFocusMinorTarget] used by EXPAND-phase
/// candidate scoring (`diplomatic_candidate_scoring_offer_peace.dart` and
/// the seed-42 gp4 minor-front-hold path) so the planner does not peace a
/// minor that still owns a real OW frontier while we are below quota.
///
/// Outer guard: returns `null` when
/// [isBelowObserverConquestQuota] is `false` for
/// [ConquestSummary.oldWorldProvincesOwned] — the at-quota and above-quota
/// bands route minor-front decisions through the quota-met /
/// near-quota / consolidate deciders instead.
///
/// When the outer guard passes, the helper delegates to
/// [stalledFocusMinorTarget] and returns its result unchanged: either the
/// minor that owns the most invadable OW provinces, or `null` when the
/// scan finds no at-war minor with an invadable OW province.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7). Cost is dominated by the
/// [stalledFocusMinorTarget] scan once the outer guard passes; the
/// quota-band check is O(1).
String? belowQuotaActiveMinorWarTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return null;
  }
  return stalledFocusMinorTarget(game: game, snapshot: snapshot);
}

/// Returns the deterministic ascending-sorted list of at-war minor
/// `factionId`s the active player should `offerPeace` toward in EXPAND
/// while below the observer OW quota with a regiment count too small to
/// split across multiple minor wars, dropping every distraction minor
/// front except the focused-minor target, or `const []` when the
/// distraction-peace pivot does not apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `belowQuotaMultiMinorDistractionPeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. The decider
/// implements the EXPAND-phase "while below quota and regiment-thin,
/// peace every distracting at-war minor so the few regiments we have
/// concentrate on the focused single-front minor" pivot used by the
/// seed-42 gp4 zero-gain stall: gp4 fights minor1 and minor2 with only
/// one or two regiments and the planner needs to drop one war so the
/// remaining regiments can finish the focused frontier.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — at and above quota
///      the quota-met / consolidate / near-quota deciders own the
///      multi-minor decision instead.
///   2. `regimentCount <= 0` — zero-regiment survival deciders
///      ([stalledZeroRegimentAllFactionPeaceTargets],
///      [stalledZeroRegimentGpPeaceTargets]) own the peace decision
///      below the affordability gate; this decider does not also
///      compete for that zero band.
///   3. `regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
///      — once the active player can afford to declare and project
///      across multiple fronts the multi-minor distraction pivot is
///      not warranted; the planner can sustain the additional minor
///      wars while it walks the EXPAND ratchet.
///   4. [ConquestSummary.invadableProvinceIdsSorted] is empty — no
///      OW frontier means no minor war to concentrate on.
///   5. [stalledFocusMinorTarget] returns `null` — without an at-war
///      minor owning an invadable OW province the distraction-peace
///      pivot has no target to preserve.
///
/// When the guards pass:
///   * Walks [ThreatSummary.atWarWith] in iteration order and keeps
///     every entry that is a member of [Game.minorNations] (tribes
///     and Great Powers are dropped because the GP-blocker, peer-GP,
///     and GP-distraction-tribe deciders own those decisions) and is
///     not the focused-minor target preserved by
///     [stalledFocusMinorTarget].
///   * Sorts the result ascending so emission order is deterministic
///     for fixed inputs (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `diplomacy_planner_below_quota_peace_part3_test.dart`
/// fixture and the in-file `collectStalledGreatPowerPeaceTargets`
/// `minorTribePeace` consumer chain until the now-completed S1 deletion of
/// that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7). Cost is dominated by the
/// [stalledFocusMinorTarget] scan once the outer guards pass plus a
/// single pass over [ThreatSummary.atWarWith]; matches the budget-rule
/// note in `colonizethis-turn-resolution-budget.mdc` (no global
/// province / tile scans introduced by the move).
List<String> belowQuotaMultiMinorDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return const [];
  }
  final regimentCount = regimentCountForPlayer(game, snapshot.playerId);
  if (regimentCount <= 0 ||
      regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final focus = stalledFocusMinorTarget(game: game, snapshot: snapshot);
  if (focus == null) {
    return const [];
  }
  // Route the at-war-minor filter + ascending sort through the shared
  // [minorAtWarPeaceTargetsWhere] collector (Refs #3717 expand-peace
  // scoring-skeleton dedup); only the focused-minor exclusion remains
  // caller-specific. Byte-identical to the inline `isMinorFaction` + sort.
  return minorAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) => factionId != focus,
  );
}

