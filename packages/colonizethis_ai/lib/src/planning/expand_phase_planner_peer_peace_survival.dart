/// EXPAND-phase peer-peace: critical weak-GP survival and critical multi-front peace (Refs #3967 step 4).
///
/// Topic split from `expand_phase_planner_peer_peace.dart`; public
/// symbols remain re-exported by that barrel.
library;

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner_peer_peace_stalled.dart'
    show multiFrontNonBlockerGpPeaceTargets;
import 'planning_helpers.dart'
    show gpAtWarPeaceTargetsWhere, gpFactionIdsAtWarWith;
import 'planning_imports.dart';

/// Returns the deterministic list of stronger at-war Great Power
/// factionIds the active player should `offerPeace` toward this turn
/// when OW holdings are critically low — the EXPAND-phase
/// critical-survival peace arm that peaces every stronger GP foe so
/// the active player can rebuild without losing the few OW provinces
/// it still holds.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `criticalWeakGpSurvivalPeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. Implements
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when OW
/// holdings are critically low (`<= kFewOldWorldProvincesDefendThreshold`)
/// peace every stronger at-war Great Power so a multi-front GP collapse
/// cannot eliminate the active player".
///
/// Returns `const []` for the outer guard:
///   * [ConquestSummary.oldWorldProvincesOwned] is strictly above
///     [kFewOldWorldProvincesDefendThreshold] (today: 6). Outside the
///     critical band the broader [criticalOwHoldPeaceTargets] and
///     band-specific deciders own the decision.
///
/// When the guard passes the function iterates [ThreatSummary.atWarWith]
/// and selects every Great Power foe (filtered via [Game.playerById])
/// whose own [provinceCountOwnedBy] satisfies the band-dependent
/// minimum-lead threshold:
///
///   * `ownOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1`
///     (today: 7 + 1 = 8) — default-start critical row: lead `>= 1`
///     is enough (any stronger GP is a critical risk while the player
///     is barely above the observer default start).
///   * Else `isBelowObserverConquestQuota(ownOw)` — below-quota critical
///     row: lead `>= kUnwinnableSoleGpMinProvinceDeficit` (today: 2) so
///     a slightly-stronger below-quota peer does not get peaced away
///     for free.
///   * Else (above-quota critical-band shape, defensive) —
///     lead `>= kDeclareWarAggressorSuppressWeakGpLeadThreshold`
///     (today: 4) so only clearly dominant peers are peaced.
///
/// Tribes and minors are dropped silently ([Game.playerById] returns
/// `null` for those ids); the returned list is sorted ascending by
/// `factionId` so the downstream survival aggregator
/// (`_survivalGreatPowerPeaceTargets`) and the legacy
/// `stalledOwExpansionNeedsPeacePass` consumer see a stable order
/// regardless of [ThreatSummary.atWarWith] iteration order (Refs #2509
/// Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `diplomacy_planner_mutual_exhausted_peace_test.dart`
/// and `diplomacy_planner_stalled_peace_test.dart` fixtures and the
/// in-file `_survivalGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains so the planned
/// S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// (each at-war faction is inspected once with one [provinceCountOwnedBy]
/// scan); constant-time on every other arm. No global province / tile
/// scans introduced by the move, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
List<String> criticalWeakGpSurvivalPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.oldWorldProvincesOwned >
      kFewOldWorldProvincesDefendThreshold) {
    return const [];
  }
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  final minLead = ownOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1
      ? 1
      : isBelowObserverConquestQuota(ownOw)
      ? kUnwinnableSoleGpMinProvinceDeficit
      : kDeclareWarAggressorSuppressWeakGpLeadThreshold;
  return gpAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) =>
        provinceCountOwnedBy(game, factionId) >= ownOw + minLead,
  );
}

/// Returns the deterministic list of non-blocker at-war Great Power
/// factionIds the active player should `offerPeace` toward this turn
/// when fighting two or more Great Powers and still inside the
/// EXPAND-band expansion pressure or at-quota band — the EXPAND-phase
/// critical multi-front peace arm that avoids total collapse from
/// simultaneous GP wars by dropping every non-blocker GP front.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `criticalMultiFrontGpPeaceTargets` peace decider previously hosted
/// in `diplomacy_planner_peace_targets.dart`. Composes the canonical
/// [multiFrontNonBlockerGpPeaceTargets] helper for the actual
/// non-blocker selection; this decider adds the EXPAND-band outer
/// guard and the 2+ GP-fronts precondition that distinguish the
/// critical multi-front signal from the general multi-front pivot.
///
/// Returns `const []` for any of the two outer guards:
///   1. Both [isObserverConquestExpansionPressure] and
///      [isAtObserverConquestQuotaBand] return `false` for the active
///      player's [ConquestSummary.oldWorldProvincesOwned] — outside the
///      EXPAND-band expansion pressure shape and the at-quota band the
///      critical multi-front pivot does not apply (the broader
///      quota-met deciders own the decision instead).
///   2. Fewer than two Great Powers remain in [ThreatSummary.atWarWith]
///      (after the [Game.playerById] filter) — the "multi-front"
///      precondition does not hold so the broader
///      [multiFrontNonBlockerGpPeaceTargets] sole-non-blocker arm and
///      the EXPAND default-start / near-quota collectors own the
///      single-GP cases.
///
/// When the guards pass the function delegates to
/// [multiFrontNonBlockerGpPeaceTargets] for the deterministic
/// non-blocker selection (primary OW frontier blocker is held open;
/// every other GP foe is peaced) sorted ascending by `factionId`
/// (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `diplomacy_planner_below_quota_peace_part3_test.dart`
/// and `diplomacy_planner_stalled_peace_test.dart` fixtures and the
/// in-file `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains so the planned
/// S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// for the GP filter plus the delegated
/// [multiFrontNonBlockerGpPeaceTargets] body; no new global province /
/// tile scans introduced by the move, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
List<String> criticalMultiFrontGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isObserverConquestExpansionPressure(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      !isAtObserverConquestQuotaBand(
        snapshot.conquest.oldWorldProvincesOwned,
      )) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length < 2) {
    return const [];
  }
  return multiFrontNonBlockerGpPeaceTargets(game: game, snapshot: snapshot);
}
