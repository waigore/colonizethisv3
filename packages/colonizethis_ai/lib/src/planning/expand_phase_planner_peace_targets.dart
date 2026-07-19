import '../perception/perception_snapshot.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';


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

/// Returns the deterministic list of below-quota at-war Great Power
/// factionIds the active quota-met player should `offerPeace` toward this
/// turn — the "stop bullying below-quota peers" arm of the EXPAND-phase
/// peace family.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `quotaMetBelowQuotaAtWarPeaceTargets` peace decider previously hosted
/// in `colonial_pressure.dart`. The decider is the broadest quota-met
/// futile-war exit: once the active player has crossed the observer OW
/// quota ([kObserverConquestMinOwProvincesPerGp] today), every below-
/// quota Great Power still at war is offered peace so the planner stops
/// dragging on mop-up wars after the frontier is cleared
/// (`SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when this GP
/// already meets the observer quota and a below-quota Great Power at
/// war ... exit futile bullying wars; observer seed-42 gp4/gp3").
///
/// The companion [quotaMetFutileBelowQuotaGpPeaceTargets] narrows the
/// same family by also requiring the active player to still hold an
/// invadable OW frontier — used by the offer-peace scoring layer
/// (`diplomatic_candidate_scoring_offer_peace.dart`) so only the
/// narrower set carries the futile-bullying score bonus. The broader
/// helper here covers the post-cleanup state where no invadable OW
/// frontier remains and the planner just wants to release the residual
/// below-quota wars.
///
/// Returns `const []` for either of the outer guards:
///   1. [isBelowObserverConquestQuota] is `true` for the active player's
///      [ConquestSummary.oldWorldProvincesOwned] — quota-met peace
///      targets only fire after this GP has already crossed the
///      observer quota; below-quota GPs are still pressing war and
///      must defer to the EXPAND-phase peace deciders
///      ([defaultStartFutileMinorPeaceTargets],
///      [unwinnableSoleGpFrontierPeaceTarget], the in-file
///      `colonial_pressure` peace collectors that have not yet been
///      relocated).
///   2. [ThreatSummary.atWarWith] contains no Great Power below the
///      observer quota — the active player has only quota-met peers
///      (or no GP foes at all), so the consolidate-gains decider
///      ([consolidateGainsSoleGpPeaceTarget]) and the broader
///      multi-front peace collectors own the decision.
///
/// Per-enemy filters (each `continue`s without short-circuiting):
///   * Skip [ThreatSummary.atWarWith] entries that are not Great
///     Powers ([Game.playerById] returns `null`); minors and tribes
///     belong to the [defaultStartFutileMinorPeaceTargets] family.
///   * Skip Great Power enemies whose own
///     [provinceCountOwnedBy] is at or above the observer quota;
///     consolidate-gains owns those wars.
///
/// The returned list is sorted ascending by `factionId` so the
/// downstream offer-peace consumer (`diplomacy_planner_peace_targets.dart`,
/// `diplomatic_candidate_scoring_offer_peace.dart`) sees a stable
/// order regardless of the iteration order of
/// [ThreatSummary.atWarWith] (Refs #2509 Must-have #7).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the
/// `colonial_pressure_quota_met_below_quota_at_war_peace_branches_test.dart`
/// fixture and the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` consumer chain) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] × [provinceCountOwnedBy] (one full
/// province scan per at-war faction).
List<String> quotaMetBelowQuotaAtWarPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (isOwnOldWorldBelowConquestQuota(snapshot)) {
    return const [];
  }
  return gpAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) =>
        isBelowObserverConquestQuota(provinceCountOwnedBy(game, factionId)),
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

/// Returns the deterministic list of below-quota at-war Great Power
/// factionIds the active quota-met player should `offerPeace` toward
/// this turn — the "stop bullying below-quota peers that are not
/// blocking my remaining OW frontier" arm of the EXPAND-phase peace
/// family.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `quotaMetFutileBelowQuotaGpPeaceTargets` peace decider previously
/// hosted in `colonial_pressure.dart`. The decider narrows the broader
/// [quotaMetBelowQuotaAtWarPeaceTargets] family by additionally requiring
/// the active player to still hold an invadable OW frontier and by
/// excluding any below-quota enemy GP that owns one of those invadable
/// OW provinces (peace there would forfeit the residual OW acquisition
/// path) plus the primary invadable OW blocker
/// ([primaryInvadableOldWorldGpBlocker]; defensive backstop). The
/// consumer (`diplomatic_candidate_scoring_offer_peace.dart`) applies a
/// stronger offer-peace score bonus to this narrower set so the
/// futile-bullying signal is concentrated on the truly off-frontier
/// below-quota peers (`SPEC/ai/ai-architecture.md` § Diplomacy
/// targeting — "when this GP already meets the observer quota and a
/// below-quota Great Power at war is not on the remaining invadable OW
/// frontier ... exit futile bullying wars").
///
/// Returns `const []` for any of the three outer guards:
///   1. [isBelowObserverConquestQuota] is `true` for the active
///      player's [ConquestSummary.oldWorldProvincesOwned] — quota-met
///      peace targets only fire after this GP has already crossed the
///      observer quota.
///   2. [ConquestSummary.invadableProvinceIdsSorted] is empty — without
///      a remaining invadable OW frontier the frontier-ownership
///      filter is meaningless and the broader
///      [quotaMetBelowQuotaAtWarPeaceTargets] / consolidate-gains
///      deciders take over.
///
/// Per-enemy filters (applied via the shared [gpAtWarPeaceTargetsWhere]
/// collector's `keep` predicate; non-matching enemies are dropped without
/// short-circuiting the scan):
///   * Skip [ThreatSummary.atWarWith] entries that are not Great
///     Powers ([Game.playerById] returns `null`); minors and tribes
///     belong to the [defaultStartFutileMinorPeaceTargets] family.
///     (Applied once inside [gpAtWarPeaceTargetsWhere] / [gpFactionIdsAtWarWith].)
///   * Skip Great Power enemies whose own
///     [provinceCountOwnedBy] is at or above the observer quota;
///     consolidate-gains owns those wars.
///   * Skip Great Power enemies that own at least one province in
///     [ConquestSummary.invadableProvinceIdsSorted] (peace would
///     forfeit the residual OW acquisition path).
///   * Skip the primary invadable OW blocker
///     ([primaryInvadableOldWorldGpBlocker]) defensively — by
///     construction the blocker also satisfies the invadable-owning
///     filter above, so the equality skip is a backstop against a
///     future blocker-resolution refactor that could decouple blocker
///     identity from invadable ownership.
///
/// The returned list is sorted ascending by `factionId` so the
/// downstream offer-peace consumer
/// (`diplomatic_candidate_scoring_offer_peace.dart`) sees a stable
/// order regardless of the iteration order of
/// [ThreatSummary.atWarWith] (Refs #2509 Must-have #7).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the
/// `colonial_pressure_quota_met_futile_below_quota_gp_peace_branches_test.dart`
/// fixture, the `diplomacy_planner_stalled_peace_test.dart` sole
/// positive-case fixture, and the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` /
/// `diplomatic_candidate_scoring_offer_peace.dart` consumer chains)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] × ([provinceCountOwnedBy] +
/// [ConquestSummary.invadableProvinceIdsSorted]) for the per-enemy
/// frontier-ownership scan.
List<String> quotaMetFutileBelowQuotaGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (isOwnOldWorldBelowConquestQuota(snapshot)) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  // Route the GP at-war filter + ascending-`factionId` sort through the shared
  // [gpAtWarPeaceTargetsWhere] collector skeleton (Refs #3717 expand-peace
  // dedup), matching the sibling deciders [stalledBelowQuotaGpLeadPeaceTargets]
  // and [quotaMetBelowQuotaAtWarPeaceTargets]. Byte-identical: the inline loop
  // skipped non-GP `atWarWith` entries and sorted the result, exactly what the
  // shared helper does; only the below-quota / invadable-owner / blocker
  // per-enemy filters remain caller-specific here.
  return gpAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) {
      if (!isBelowObserverConquestQuota(
        provinceCountOwnedBy(game, factionId),
      )) {
        return false;
      }
      final ownsInvadable = factionOwnsInvadableOldWorldProvince(
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        factionId: factionId,
      );
      return !(ownsInvadable || factionId == blocker);
    },
  );
}
