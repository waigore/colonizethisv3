import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart';

export 'observer_goal_phase_stalled_peace.dart'
    show
        collectStalledGreatPowerPeaceTargets,
        supplementMutualStalledGreatPowerPeaceOrders;

/// Observer tuning phases for Full AI (Refs #2509 S10).
enum ObserverGoalPhase {
  /// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` — OW expansion first.
  expand,

  /// Turn ≥120 safeguard: near-quota EXPAND with global NW still non-GP-owned.
  colonialLite,

  /// OW quota met and sea-reachable NW / colonial targets remain.
  colonial,

  /// OW quota met; no visible colonial acquisition targets — improve extractable tiles.
  develop,
}

/// Whether any `newWorld|` province is unowned or owned by a non-GP faction.
bool globalNewWorldHasNonGpOwnership(Game game) {
  final cache = ProvinceOwnerCache.of(game.worldState);
  for (final p in cache.unownedProvinces) {
    if (p.regionId == kRegionNewWorld) return true;
  }
  for (final ownerId in cache.ownerIds) {
    if (!cache.ownsAnyInRegion(ownerId, kRegionNewWorld)) continue;
    if (ownerId.isEmpty || game.playerById(ownerId) == null) return true;
  }
  return false;
}

/// Sea-reachable unowned NW provinces or tribe/minor owners still to clear.
///
/// EXPAND -> COLONIAL phase transition guard for `observerGoalPhaseFor`.
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the guard
/// survives the planned deletion of `colonial_pressure.dart`.
bool hasColonialAcquisitionTargets(ColonialSummary colonial) =>
    colonial.invadableNewWorldProvinceIdsSorted.isNotEmpty ||
    colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty;

/// Early colonial expansion bonus while the GP holds fewer than
/// [kColonialFewNwProvincesThreshold] NW provinces and visible colonial
/// acquisition targets remain.
///
/// Fires the `goal_manager.dart` early-colonial conquer bonus alongside the
/// `hasColonialAcquisitionTargets` guard above. Relocated from
/// `colonial_pressure.dart` (Refs #2509 S1) so the predicate survives the
/// planned deletion of `colonial_pressure.dart`. Pure function of
/// [ColonialSummary]; deterministic for identical inputs (Must-have #7).
bool isEarlyColonialExpansion(ColonialSummary colonial) =>
    hasColonialAcquisitionTargets(colonial) &&
    colonial.newWorldProvincesOwned < kColonialFewNwProvincesThreshold;

/// COLONIAL-lite: turn ≥120, OW ≥9 and below quota, global NW not fully GP-owned.
bool isObserverColonialLitePhase({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (ownOw < kObserverColonialLiteNearQuotaOw) {
    return false;
  }
  if (!isBelowObserverConquestQuota(ownOw)) {
    return false;
  }
  if (game.worldState.turnState.turnNumber < kObserverColonialLiteMinTurn) {
    return false;
  }
  return globalNewWorldHasNonGpOwnership(game);
}

/// Deterministic phase from [AIWorldSnapshot] (PlayerView-derived; Refs #2509).
ObserverGoalPhase observerGoalPhaseFor({
  required AIWorldSnapshot snapshot,
  Game? game,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (isBelowObserverConquestQuota(ownOw)) {
    if (game != null &&
        isObserverColonialLitePhase(game: game, snapshot: snapshot)) {
      return ObserverGoalPhase.colonialLite;
    }
    return ObserverGoalPhase.expand;
  }
  if (hasColonialAcquisitionTargets(snapshot.colonial)) {
    return ObserverGoalPhase.colonial;
  }
  return ObserverGoalPhase.develop;
}

bool isObserverDevelopPhase({required AIWorldSnapshot snapshot, Game? game}) =>
    observerGoalPhaseFor(snapshot: snapshot, game: game) ==
    ObserverGoalPhase.develop;

/// EXPAND: peace non-blocker Great Power fronts when fighting 2+ GPs (Refs #2509 S10).
List<String> expandPhaseGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!(observerGoalPhaseFor(snapshot: snapshot, game: game) ==
      ObserverGoalPhase.expand)) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  // Minor-first: exit every GP front while uninvaded minors remain (Refs #2509).
  if (gpWars.isNotEmpty &&
      hasUninvadedOldWorldMinor(game: game, snapshot: snapshot) &&
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return gpWars..sort();
  }
  if (gpWars.length == 1) {
    final soleGp = gpWars.single;
    final ownOw = snapshot.conquest.oldWorldProvincesOwned;
    final partnerOw = provinceCountOwnedBy(game, soleGp);
    if (isMutualBelowQuotaPlateauPeer(ownOw: ownOw, partnerOw: partnerOw) &&
        isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot) &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return gpWars;
    }
    return const [];
  }
  if (gpWars.isEmpty) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null || !gpWars.contains(blocker)) {
    return const [];
  }
  return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
}

/// GP owning the most invadable New World provinces (colonial frontier blocker).
///
/// Tally GP ownership in a single pass, then resolve the plurality winner in a
/// second linear pass that preserves the original first-iterated-province
/// tiebreak (sorted `invadableNewWorldProvinceIdsSorted`). Behaviorally
/// identical to the prior nested-loop implementation but linear in the
/// invadable-NW set rather than quadratic; relevant on hot peace-target
/// collection paths (Refs `colonizethis-turn-resolution-budget.mdc`
/// "Memoize per-target/per-player computations inside hot loops").
String? primaryColonialGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final counts = <String, int>{};
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null || game.playerById(owner) == null) {
      continue;
    }
    counts[owner] = (counts[owner] ?? 0) + 1;
  }
  if (counts.isEmpty) {
    return null;
  }
  String? bestGpId;
  var bestCount = 0;
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null) {
      continue;
    }
    final count = counts[owner];
    if (count == null) {
      continue;
    }
    if (count > bestCount) {
      bestCount = count;
      bestGpId = owner;
    }
  }
  return bestGpId;
}

/// COLONIAL: peace non-blocker Great Power fronts when fighting 2+ GPs (Refs #2509 S10).
List<String> colonialPhaseGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!(observerGoalPhaseFor(snapshot: snapshot, game: game) ==
      ObserverGoalPhase.colonial)) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length <= 1) {
    return const [];
  }
  final blocker = primaryColonialGpBlocker(game: game, snapshot: snapshot);
  if (blocker == null || !gpWars.contains(blocker)) {
    return const [];
  }
  return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
}

/// EXPAND phase: suppress NW colonial diplomacy, military, civilian, and naval work.
bool shouldSuppressNewWorldColonialOrders({
  required AIWorldSnapshot snapshot,
  Game? game,
}) =>
    observerGoalPhaseFor(snapshot: snapshot, game: game) ==
    ObserverGoalPhase.expand;

/// EXPAND, COLONIAL-lite, and DEVELOP: no NW declare-war, invasion, or purchase_land.
bool shouldSuppressNewWorldDeclareWarInvasionAndPurchase({
  required AIWorldSnapshot snapshot,
  Game? game,
}) {
  switch (observerGoalPhaseFor(snapshot: snapshot, game: game)) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
    case ObserverGoalPhase.develop:
      return true;
    case ObserverGoalPhase.colonial:
      return false;
  }
}

/// DEVELOP: peace all at-war Great Powers (Refs #2509 S10).
List<String> developPhaseGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isObserverDevelopPhase(snapshot: snapshot, game: game)) {
    return const [];
  }
  return gpFactionIdsAtWarWith(game, snapshot);
}

/// Signature shared by every EXPAND-regime Great Power peace decider composed
/// by the ordered registries below (Refs #3749 step 5 — expand-peace decider
/// registry). Each decider is a pure projection of `(game, snapshot)` to the
/// Great Power faction ids it votes to `offerPeace` toward this turn; the
/// aggregators concatenate the deciders in registry order so the per-decider
/// precedence is expressed once as data rather than as a hand-unrolled `yield*`
/// chain. Multi-target deciders return a `List<String>` (assignable to this
/// `Iterable<String>` return via covariant function subtyping); the three
/// single-target deciders are adapted to this shape by the thin
/// `_…PeaceDecider` wrappers below so their `String?` results join the same
/// registry without changing their exported symbols. Pure and deterministic —
/// identical inputs always yield identical output (Refs #2509 Must-have #7).
typedef ExpandPeaceDecider =
    Iterable<String> Function({
      required Game game,
      required AIWorldSnapshot snapshot,
    });

/// Adapts a `String?` single-target peace decider result to the
/// [ExpandPeaceDecider] `Iterable<String>` shape: an empty list when no target
/// is voted, else a single-element list. Keeps the underlying single-target
/// deciders' exported `String?` symbols unchanged while letting them sit in the
/// ordered registry alongside the multi-target collectors.
Iterable<String> _singleTargetOrEmpty(String? target) =>
    target == null ? const <String>[] : <String>[target];

/// [ExpandPeaceDecider] wrapper for [stalledStrongerGpBlockerPeaceTarget].
Iterable<String> _stalledStrongerGpBlockerPeaceDecider({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => _singleTargetOrEmpty(
  stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
);

/// [ExpandPeaceDecider] wrapper for [unwinnableSoleGpFrontierPeaceTarget].
Iterable<String> _unwinnableSoleGpFrontierPeaceDecider({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => _singleTargetOrEmpty(
  unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
);

/// [ExpandPeaceDecider] wrapper for [consolidateGainsSoleGpPeaceTarget].
Iterable<String> _consolidateGainsSoleGpPeaceDecider({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => _singleTargetOrEmpty(
  consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
);

/// Ordered survival / zero-regiment / mutual-exhausted peace deciders consumed
/// by [survivalGreatPowerPeaceTargets] (Refs #3749 step 5). The list order is
/// the canonical precedence and must match the legacy `yield*` order exactly;
/// see [survivalGreatPowerPeaceTargets] for the per-decider contract.
const List<ExpandPeaceDecider> kSurvivalGreatPowerPeaceDeciders =
    <ExpandPeaceDecider>[
      criticalWeakGpSurvivalPeaceTargets,
      stalledZeroRegimentAllFactionPeaceTargets,
      mutualZeroRegimentGpStalematePeaceTargets,
      stalledZeroRegimentGpPeaceTargets,
      mutualExhaustedBelowQuotaGpStalematePeaceTargets,
    ];

/// Ordered EXPAND-regime ratchet peace deciders consumed by
/// [expandRatchetGreatPowerPeaceTargets] (Refs #3749 step 5). The list order is
/// the canonical precedence and must match the legacy `yield*` order exactly,
/// including the interleaved single-target deciders adapted via the
/// `_…PeaceDecider` wrappers above; see [expandRatchetGreatPowerPeaceTargets]
/// for the per-decider contract.
const List<ExpandPeaceDecider> kExpandRatchetGreatPowerPeaceDeciders =
    <ExpandPeaceDecider>[
      stalledFutileGpPeaceTargets,
      stalledGpBlockerFocusPeaceTargets,
      stalledExpansionDistractionPeaceTargets,
      multiFrontNonBlockerGpPeaceTargets,
      criticalMultiFrontGpPeaceTargets,
      weakHoldingsInvadableBlockerPeaceTargets,
      _stalledStrongerGpBlockerPeaceDecider,
      criticalOwHoldPeaceTargets,
      stalledBelowQuotaGpLeadPeaceTargets,
      belowQuotaPeerGpPeaceTargets,
      defaultStartGpPeaceTargets,
      defaultStartFutileMinorPeaceTargets,
      nearQuotaHoldPeaceTargets,
      quotaMetBelowQuotaAtWarPeaceTargets,
      quotaMetFutileBelowQuotaGpPeaceTargets,
      _unwinnableSoleGpFrontierPeaceDecider,
      _consolidateGainsSoleGpPeaceDecider,
    ];

/// Critical-collapse / zero-regiment peace aggregator for all observer phases.
///
/// Canonical home (Refs #2509 S1) for the legacy private
/// `_survivalGreatPowerPeaceTargets` helper previously hosted in
/// `diplomacy_planner_peace_targets.dart`. The aggregator collects all
/// survival / zero-regiment / mutual-exhausted peace deciders into a
/// single yield, preserving the same precedence order as the legacy code.
///
/// Called by [collectStalledGreatPowerPeaceTargets] which is the single
/// public entry for the GP peace-targets set consumed by the diplomacy
/// planner. `diplomacy_planner_peace_targets.dart` previously retained a thin
/// delegating stub until the now-completed S1 deletion of that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7).
Iterable<String> survivalGreatPowerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) sync* {
  for (final decider in kSurvivalGreatPowerPeaceDeciders) {
    yield* decider(game: game, snapshot: snapshot);
  }
}

/// Legacy OW-expansion scoring ratchet peace aggregator (EXPAND / COLONIAL-lite only; Refs #2509 S10).
///
/// Canonical home (Refs #2509 S1) for the legacy private
/// `_expandRatchetGreatPowerPeaceTargets` helper previously hosted in
/// `diplomacy_planner_peace_targets.dart`. The aggregator collects all
/// EXPAND-regime peace deciders from the expanded canonical set (22
/// helpers in `expand_phase_planner.dart` and its part files) into a
/// single yield, preserving the same precedence order as the legacy code.
///
/// Called by [collectStalledGreatPowerPeaceTargets] which is the single
/// public entry for the GP peace-targets set consumed by the diplomacy
/// planner. `diplomacy_planner_peace_targets.dart` previously retained a thin
/// delegating stub until the now-completed S1 deletion of that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7).
Iterable<String> expandRatchetGreatPowerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) sync* {
  for (final decider in kExpandRatchetGreatPowerPeaceDeciders) {
    yield* decider(game: game, snapshot: snapshot);
  }
}
