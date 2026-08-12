import '../perception/perception_snapshot.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

export 'expand_phase_planner_peace_targets_quota_met.dart';
export 'expand_phase_planner_peace_targets_stalled.dart';

/// Returns the deterministic list of at-war Great Powers the active
/// player should `offerPeace` toward this turn when below the observer
/// OW quota and a GP enemy leads by at least the band-selected minimum
/// province deficit.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledBelowQuotaGpLeadPeaceTargets` peace decider previously hosted
/// in `colonial_pressure.dart`. Implements the EXPAND-phase "peace the
/// leaders, hold the blocker" arm from
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — peace at-war
/// Great Powers that lead by [kUnwinnableSoleGpMinProvinceDeficit] (the
/// default-start band) or **1** (post-default band) OW provinces or
/// more while strictly below [kObserverConquestMinOwProvincesPerGp].
///
/// Contract:
///
///   1. **Quota guard.** When
///      [ConquestSummary.oldWorldProvincesOwned] is at or above
///      [kObserverConquestMinOwProvincesPerGp] return `const []` —
///      the caller falls through to quota-met deciders
///      ([quotaMetBelowQuotaAtWarPeaceTargets] / [consolidateGainsSoleGpPeaceTarget])
///      instead of the below-quota lead-peace family.
///   2. **Min-lead-deficit band.** With `own <=
///      kObserverDefaultStartOldWorldProvincesPerGp` the lead threshold
///      is [kUnwinnableSoleGpMinProvinceDeficit] (default-start row);
///      above default start (8–9 OW) the threshold relaxes to **1**
///      (post-default row).
///   3. **GP-only invadable blocker carve-out.** When
///      [isOldWorldGpOnlyInvadableFrontier] is true the
///      [primaryInvadableOldWorldGpBlocker] is excluded from the peace
///      list so the active player keeps fighting the canonical OW
///      frontier blocker even if it leads by the band-selected
///      deficit. Non-blocker GP enemies that still satisfy the
///      deficit remain in the list.
///   4. **At-war filter.** Tribes and minors in [ThreatSummary.atWarWith]
///      are skipped (`game.playerById(...) != null`); only GP factions
///      survive the filter.
///   5. **Lead filter.** Only GP factions whose
///      [provinceCountOwnedBy] is at least `own + minLeadDeficit`
///      survive the deficit gate.
///   6. **Sort determinism.** The returned list is sorted ascending
///      on `factionId` so the downstream offer-peace pass observes a
///      stable order regardless of `atWarWith` iteration order.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `colonial_pressure_stalled_below_quota_gp_lead_branches_test.dart`
/// fixture and the
/// `diplomatic_candidate_scoring_offer_peace.dart` / `diplomacy_planner.dart`
/// / `diplomacy_planner_peace_targets.dart` consumer chains) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] (each at-war faction is inspected once)
/// and in [ConquestSummary.invadableProvinceIdsSorted] via the
/// GP-only-frontier composite that gates the blocker carve-out.
List<String> stalledBelowQuotaGpLeadPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return const [];
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  final minLeadDeficit = own <= kObserverDefaultStartOldWorldProvincesPerGp
      ? kUnwinnableSoleGpMinProvinceDeficit
      : 1;
  final invadableBlocker =
      isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  return gpAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) =>
        factionId != invadableBlocker &&
        provinceCountOwnedBy(game, factionId) >= own + minLeadDeficit,
  );
}

/// Returns the deterministic list of at-war Great Powers the active
/// player should `offerPeace` toward this turn when OW holdings are
/// critically low (at or below [kFewOldWorldProvincesDefendThreshold])
/// and the player is still below the observer OW quota — the
/// EXPAND-phase critical-hold peace arm that peaces every GP war
/// regardless of frontier shape so the GP can rebuild without losing
/// the few OW provinces it still holds.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `criticalOwHoldPeaceTargets` peace decider previously hosted in
/// `colonial_pressure.dart`. Implements
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when OW
/// holdings are at or below `kFewOldWorldProvincesDefendThreshold` and
/// any OW minor remains (peace all GP wars)".
///
/// Contract:
///
///   1. **At-war filter.** [ThreatSummary.atWarWith] is filtered to
///      Great Power factions via [Game.playerById]; tribes and minors
///      are skipped. The returned list is sorted ascending on
///      `factionId` before any short-circuit so the empty-after-filter
///      branch and the firing branch share the same sort order.
///   2. **Empty-after-filter short-circuit.** When no GP factions
///      remain in the filtered list the function returns `const []`
///      immediately even if the OW critical band would otherwise fire.
///   3. **Own-OW critical band.** The peace list is emitted only when
///      [isBelowObserverConquestQuota] holds and
///      [ConquestSummary.oldWorldProvincesOwned] is at or below
///      [kFewOldWorldProvincesDefendThreshold]. Outside this band — at
///      or above the observer quota, or below the quota but strictly
///      above the defend threshold — the function returns `const []`.
///   4. **Below-quota AND-gate.** Both gates must hold: at-quota holdings
///      below the defend threshold still return `const []` because
///      `isBelowObserverConquestQuota` is `false` (defensive against a
///      future quota change that drops the quota below the defend
///      threshold).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `colonial_pressure_critical_ow_hold_branches_test.dart`
/// and `colonial_pressure_test.dart` fixtures and the
/// `diplomacy_planner.dart` / `diplomacy_planner_peace_targets.dart`
/// consumer chains) so the now-completed S1 deletion of that file leaves no
/// orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// (each at-war faction is inspected once); constant-time on every
/// other arm.
List<String> criticalOwHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  final targets = gpFactionIdsAtWarWith(game, snapshot);
  if (targets.isEmpty) {
    return const [];
  }
  if (isBelowObserverConquestQuota(ownOw) &&
      ownOw <= kFewOldWorldProvincesDefendThreshold) {
    return targets;
  }
  return const [];
}
