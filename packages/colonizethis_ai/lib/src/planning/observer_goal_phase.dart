import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart';

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
  return <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
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
  return <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
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
  yield* criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot);
  yield* stalledZeroRegimentAllFactionPeaceTargets(
    game: game,
    snapshot: snapshot,
  );
  yield* mutualZeroRegimentGpStalematePeaceTargets(
    game: game,
    snapshot: snapshot,
  );
  yield* stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot);
  yield* mutualExhaustedBelowQuotaGpStalematePeaceTargets(
    game: game,
    snapshot: snapshot,
  );
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
  yield* stalledFutileGpPeaceTargets(game: game, snapshot: snapshot);
  yield* stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot);
  yield* stalledExpansionDistractionPeaceTargets(
    game: game,
    snapshot: snapshot,
  );
  yield* multiFrontNonBlockerGpPeaceTargets(game: game, snapshot: snapshot);
  yield* criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot);
  yield* weakHoldingsInvadableBlockerPeaceTargets(
    game: game,
    snapshot: snapshot,
  );
  final strongerBlocker = stalledStrongerGpBlockerPeaceTarget(
    game: game,
    snapshot: snapshot,
  );
  if (strongerBlocker != null) {
    yield strongerBlocker;
  }
  yield* criticalOwHoldPeaceTargets(game: game, snapshot: snapshot);
  yield* stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot);
  yield* belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot);
  yield* defaultStartGpPeaceTargets(game: game, snapshot: snapshot);
  yield* defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot);
  yield* nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot);
  yield* quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot);
  yield* quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot);
  final unwinnable = unwinnableSoleGpFrontierPeaceTarget(
    game: game,
    snapshot: snapshot,
  );
  if (unwinnable != null) {
    yield unwinnable;
  }
  final consolidate = consolidateGainsSoleGpPeaceTarget(
    game: game,
    snapshot: snapshot,
  );
  if (consolidate != null) {
    yield consolidate;
  }
}

/// Great Power peace targets from observer phase rules and stalled expansion helpers.
///
/// Canonical home (Refs #2509 S1) for the legacy `collectStalledGreatPowerPeaceTargets`
/// entry-point previously hosted in `diplomacy_planner_peace_targets.dart`. The
/// function merges phase-specific GP peace targets (`expandPhaseGpPeaceTargets`,
/// `colonialPhaseGpPeaceTargets`, `developPhaseGpPeaceTargets`) with the survival
/// and expansion-ratchet aggregators, then filters by invadable-blocker preservation
/// rules and zero-regiment stalemate overrides before adding minor/tribe distraction
/// peace targets.
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating stub until the
/// now-completed S1 deletion of that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7).
Set<String> collectStalledGreatPowerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final phase = observerGoalPhaseFor(snapshot: snapshot, game: game);
  final phaseRatchetPeace = switch (phase) {
    ObserverGoalPhase.develop => const <String>[],
    ObserverGoalPhase.colonial => atWarGpDistractionTribePeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
    ObserverGoalPhase.expand ||
    ObserverGoalPhase.colonialLite => expandRatchetGreatPowerPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).toList(),
  };
  final targets = <String>{
    ...developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
    ...colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
    ...expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
    ...survivalGreatPowerPeaceTargets(game: game, snapshot: snapshot),
    ...phaseRatchetPeace,
  };
  final invadableBlocker =
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
          isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final unwinnableBlockerPeace = unwinnableSoleGpFrontierPeaceTarget(
    game: game,
    snapshot: snapshot,
  );
  final preserveBlockerPeace = <String>{
    if (!isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot))
      ...weakHoldingsInvadableBlockerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ),
    if (unwinnableBlockerPeace != null) unwinnableBlockerPeace,
    ...quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
    ...belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
    if (snapshot.conquest.oldWorldProvincesOwned >=
        kObserverDefaultStartOldWorldProvincesPerGp)
      ...defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
    ...nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
  };
  final zeroRegimentBlockerPeace = <String>{
    ...mutualZeroRegimentGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
    ...stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
    ...mutualExhaustedBelowQuotaGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
  };
  final greatPowerPeace = targets
      .where(
        (id) =>
            game.playerById(id) != null &&
            (id != invadableBlocker ||
                preserveBlockerPeace.contains(id) ||
                zeroRegimentBlockerPeace.contains(id)),
      )
      .toSet();
  final minorTribePeace = <String>{
    ...belowQuotaMultiMinorDistractionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
    ...stalledZeroRegimentAllFactionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
  }.where((id) => game.playerById(id) == null);
  return {...greatPowerPeace, ...minorTribePeace};
}

/// GP–GP peace requires both sides to [offerPeace] in the same phase; mirror existing offers.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `supplementMutualStalledGreatPowerPeaceOrders` helper previously hosted in
/// `diplomacy_planner_peace_targets.dart`. The function mirrors declared
/// GP→GP [offerPeace] orders onto the target GP's own diplomatic orders so
/// that mutual stalled Great Power peace pairs resolve within the same
/// diplomacy planner pass.
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating stub until the
/// now-completed S1 deletion of that file.
Orders supplementMutualStalledGreatPowerPeaceOrders({
  required Game game,
  required MapTopology topology,
  required Orders orders,
}) {
  final diplo = Map<String, List<DiplomaticOrder>>.from(
    orders.diplomaticOrdersByPlayerId,
  );
  var changed = false;
  for (final entry in orders.diplomaticOrdersByPlayerId.entries) {
    final fromGp = entry.key;
    if (!isAiControlled(game, fromGp)) continue;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.offerPeace) continue;
      final toGp = order.targetFactionId;
      if (game.playerById(toGp) == null || !isAiControlled(game, toGp)) {
        continue;
      }
      final fromView = buildPlayerView(game, topology, fromGp);
      final fromSnapshot = AIWorldSnapshot.fromPlayerView(
        fromView,
        topology: topology,
      );
      final invadableBlocker = primaryInvadableOldWorldGpBlocker(
        game: game,
        snapshot: fromSnapshot,
      );
      final stalledPeaceTargets = collectStalledGreatPowerPeaceTargets(
        game: game,
        snapshot: fromSnapshot,
      );
      if (toGp == invadableBlocker && !stalledPeaceTargets.contains(toGp)) {
        continue;
      }
      final before = diplo[toGp]?.length ?? 0;
      _appendOfferPeaceIfMissing(diplo, toGp, fromGp);
      if ((diplo[toGp]?.length ?? 0) > before) {
        changed = true;
      }
    }
  }
  if (!changed) {
    return orders;
  }
  return orders.copyWith(diplomaticOrdersByPlayerId: diplo);
}

/// Low-level offer-peace insertion into a [DiplomaticOrder] list by
/// faction; no-op when the identical order is already present.
///
/// Canonical home (Refs #2509 S1) for the legacy private
/// `_appendOfferPeaceIfMissing` helper previously hosted in
/// `diplomacy_planner_peace_targets.dart`. Used by
/// [supplementMutualStalledGreatPowerPeaceOrders] to durably register
/// mirrored peace offers without duplicates.
void _appendOfferPeaceIfMissing(
  Map<String, List<DiplomaticOrder>> diplo,
  String fromGp,
  String toGp,
) {
  final existing = diplo[fromGp] ?? const [];
  if (existing.any(
    (o) =>
        o.type == DiplomaticOrderType.offerPeace && o.targetFactionId == toGp,
  )) {
    return;
  }
  diplo[fromGp] = [
    ...existing,
    DiplomaticOrder(
      type: DiplomaticOrderType.offerPeace,
      targetFactionId: toGp,
    ),
  ];
}
