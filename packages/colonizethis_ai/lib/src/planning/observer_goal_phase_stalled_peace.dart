/// Stalled Great Power peace collection / mutual supplement (Refs #4079 Slice C).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';


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
      appendOfferPeaceIfMissing(diplo, toGp, fromGp);
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
/// `appendOfferPeaceIfMissing` helper previously hosted in
/// `diplomacy_planner_peace_targets.dart`. Used by
/// [supplementMutualStalledGreatPowerPeaceOrders] to durably register
/// mirrored peace offers without duplicates.
void appendOfferPeaceIfMissing(
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
