import '../perception/perception_snapshot.dart';
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

export 'expand_phase_planner_peace_default_start_quota.dart';

/// Returns the deterministic ascending-sorted list of at-war minor
/// `factionId`s that the active player should `offerPeace` toward when
/// stuck in a futile minor war at default observer start size, or an
/// empty list when the EXPAND default-start futile-minor pivot does
/// not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `defaultStartFutileMinorPeaceTargets` peace decider previously
/// hosted in `colonial_pressure.dart`. The decider implements the
/// EXPAND-phase "exit a futile minor front before opening a GP-blocker
/// war" pivot for seed-42 gp4 (default-start GP with one zero-province
/// minor still in `threats.atWarWith`). It composes
/// [isOldWorldGpOnlyInvadableFrontier] (band selector) with the
/// observer default-start band table from
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting.
///
/// Returns the empty list (`const []`) for any of the outer guards (in
/// order):
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — at or above the
///      observer OW quota the quota-met futile-peace collectors
///      ([quotaMetFutileBelowQuotaGpPeaceTargets] et al, still in
///      `colonial_pressure.dart` at this slice) take over.
///   2. `ownOw > kObserverDefaultStartOldWorldProvincesPerGp + 1` —
///      strictly above the default-start +1 band; the near-quota /
///      stalled-band collectors own the decision in that shape.
///   3. [ConquestSummary.invadableProvinceIdsSorted] is empty — no
///      invadable OW exists for the current planner snapshot, so no
///      futile minor war can be diagnosed.
///
/// When the guards pass, the band table selects between two arms:
///   * **GP-only invadable frontier arm** — when
///     [isOldWorldGpOnlyInvadableFrontier] is `true`, every at-war
///     minor in [ThreatSummary.atWarWith] is peaced (no minor pivot
///     remains so all open minor wars are futile by construction).
///     Returned in ascending lex order over the minor `factionId`s.
///   * **Mixed minor frontier arm** — otherwise, only the at-war
///     minors that own **no** invadable OW province are peaced
///     (futile front: the minor is in `atWarWith` but not on the
///     invadable list). Resolved with [getProvinceOwnerMap] and an
///     `any` scan over [ConquestSummary.invadableProvinceIdsSorted].
///     Returned in ascending lex order over the minor `factionId`s.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` consumer chain and the
/// existing `colonial_pressure_test.dart` § `defaultStartFutileMinorPeaceTargets`
/// fixture) so the now-completed S1 deletion of that file leaves no orphan
/// callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] across both arms, plus a single
/// [getProvinceOwnerMap] pass on the mixed-frontier arm, matching the
/// budget-rule note in `colonizethis-turn-resolution-budget.mdc`
/// (no global province / tile scans introduced by the move).
List<String> defaultStartFutileMinorPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      ownOw > kObserverDefaultStartOldWorldProvincesPerGp + 1 ||
      snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  // Route the at-war-minor filter + ascending sort through the shared
  // [minorAtWarPeaceTargetsWhere] collector (Refs #3717 expand-peace
  // scoring-skeleton dedup), matching the sibling GP collector
  // [gpAtWarPeaceTargetsWhere]. Byte-identical: the GP-only arm keeps every
  // at-war minor (no extra predicate) and the mixed arm keeps only minors that
  // own no invadable OW province — the same `isMinorFaction` + sort skeleton
  // the inline comprehensions used.
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return minorAtWarPeaceTargetsWhere(game: game, snapshot: snapshot);
  }
  final provinceOwner = getProvinceOwnerMap(game);
  return minorAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) => !factionOwnsInvadableOldWorldProvince(
      snapshot: snapshot,
      provinceOwner: provinceOwner,
      factionId: factionId,
    ),
  );
}

/// Returns the deterministic ascending-sorted list of at-war Great
/// Power `factionId`s the active player should `offerPeace` toward
/// at default observer start size in EXPAND, or `const []` when the
/// default-start GP-peace pivot does not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `defaultStartGpPeaceTargets` peace decider previously hosted in
/// `colonial_pressure.dart`. The decider implements the EXPAND-phase
/// "at default observer start size, peace every Great Power war so
/// the GP can open a minor frontier" pivot for seed-42 gp4
/// (zero-gain stall, default-start band). It composes
/// [hasUninvadedOldWorldMinor], [isOldWorldGpOnlyInvadableFrontier],
/// and [primaryInvadableOldWorldGpBlocker] with the observer
/// default-start band table from `SPEC/ai/ai-architecture.md`
/// § Diplomacy targeting.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — at or above the
///      observer OW quota the quota-met futile-peace collectors
///      ([quotaMetFutileBelowQuotaGpPeaceTargets] et al, still in
///      `colonial_pressure.dart` at this slice) take over.
///   2. `ownOw > maxOwForGpPeace` where `maxOwForGpPeace` is
///      [kStalledOldWorldProvinceThreshold] when at least one
///      uninvaded OW minor remains (the planner can stretch the
///      default-start GP-peace pivot up into the stalled band) and
///      `kObserverDefaultStartOldWorldProvincesPerGp + 1` otherwise
///      (no minor pivot remains, so the pivot is restricted to the
///      default-start +1 band).
///
/// When the guards pass, the function peaces every at-war Great
/// Power faction (filtered via [Game.playerById]) **except** the
/// invadable OW frontier blocker on the GP-only invadable arm: when
/// [isOldWorldGpOnlyInvadableFrontier] is `true` the
/// [primaryInvadableOldWorldGpBlocker] is excluded so the planner
/// keeps fighting the lone GP that owns the GP-only frontier; on
/// every other shape the blocker filter is `null` and all at-war GPs
/// are peaced. The output is sorted ascending by `factionId` for
/// deterministic ordering.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for
/// legacy callers (the existing
/// `colonial_pressure_default_start_gp_peace_branches_test.dart`
/// fixture and the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` consumer chain) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] across both arms, plus the canonical
/// composite calls into [hasUninvadedOldWorldMinor],
/// [isOldWorldGpOnlyInvadableFrontier], and
/// [primaryInvadableOldWorldGpBlocker] (each linear in the OW
/// invadable / minor sets), matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc` (no global province /
/// tile scans introduced by the move).
List<String> defaultStartGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw)) {
    return const [];
  }
  final maxOwForGpPeace =
      hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)
      ? kStalledOldWorldProvinceThreshold
      : kObserverDefaultStartOldWorldProvincesPerGp + 1;
  if (ownOw > maxOwForGpPeace) {
    return const [];
  }
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  final invadableBlocker = gpOnlyFrontier
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  return gpAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) => factionId != invadableBlocker,
  );
}
