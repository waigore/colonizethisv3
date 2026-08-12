/// Quota-met EXPAND peace targets (Refs #4310 Slice B).
library;

import '../perception/perception_snapshot.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

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
