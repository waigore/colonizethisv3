part of 'conquest_planner.dart';

// Destination scoring for conquest army moves (OW/NW weight scaling
// and _scoreArmyMoveDestination) — Refs #3967 step 4.

/// Scales an OW army-move additive score term by the soft-phase
/// [oldWorldInvasionWeight] (Refs #2847 Phase 3 conquest OW-invasion wiring).
///
/// Returns `0.0` when [oldWorldInvasionWeight] is `<= 0.0` (legacy
/// hard-suppress equivalent). At `1.0` the result equals [baseBonus]
/// exactly. Intermediate weights scale linearly with clamping to `[0.0, 1.0]`.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double conquestOldWorldArmyMoveScaledBonus({
  required double baseBonus,
  required double oldWorldInvasionWeight,
}) {
  if (oldWorldInvasionWeight <= 0.0) {
    return 0.0;
  }
  final clamped = clampPhaseWeightUpperUnit(oldWorldInvasionWeight);
  return baseBonus * clamped;
}

/// NW-invadable army-move bonus contribution for the conquest destination
/// scorer (Refs #2847 Phase 2 conquest NW-invasion sign migration).
///
/// A **below-quota** GP normally pays a **negative** NW-invadable bonus so the
/// early-game OW conquest sprint stays dominant. But once a § Resource-need
/// override has lifted the dispatched `newWorldAcquisition` weight to/above
/// [kPhasePriorityNwInvadablePursuitWeightThreshold], the GP is electing to
/// pursue NW provinces for treasury income (requirement clarification #3 —
/// "resource-need overrides bypass phase priority; the AI pursues NW provinces
/// *because* it needs income to fund OW conquest"). Below quota, only the
/// treasury-recovery (`0.60`) and zero-regiment (`0.30`) override floors reach
/// that threshold; the ordinary curve plateau peaks at `0.20` at OW = 9, so it
/// never trips it. The bonus then flips **positive** so the weight biases the
/// field army *toward* the NW income foothold instead of repelling it (the
/// prior unconditional below-quota negation inverted the override, leaving
/// treasury-locked below-quota GPs unable to reach the NW foothold the
/// override exists to unlock).
///
/// At or above the OW conquest quota ([belowQuota] is `false`) the bonus is
/// always positive — the early-sprint penalty applies only below quota — so
/// healthy expanding GPs are unaffected and the magnitude scales continuously
/// with [nwInvasionWeight].
///
/// Pure and deterministic — identical `(belowQuota, nwInvasionWeight)` inputs
/// always yield the same `double` (Refs #2509 Must-have #7). Callers gate the
/// `nwInvasionWeight <= 0.0` legacy hard-suppress case (zeroed destination)
/// before invoking this helper.
double conquestNwInvadableArmyMoveBonus({
  required bool belowQuota,
  required double nwInvasionWeight,
}) {
  final pursueNwForResourceNeed =
      nwInvasionWeight >= kPhasePriorityNwInvadablePursuitWeightThreshold;
  final signedBonus = (belowQuota && !pursueNwForResourceNeed)
      ? -kConquestArmyMoveNwInvadableBonus
      : kConquestArmyMoveNwInvadableBonus;
  return signedBonus * nwInvasionWeight;
}

double _scoreArmyMoveDestination(
  ConquestMoveScoringContext ctx,
  ArmyMoveOrder move,
) {
  final nationId = ctx.nationId;
  final game = ctx.game;
  final topology = ctx.topology;
  final snapshot = ctx.snapshot;
  final provinceOwner = ctx.provinceOwner;
  final invadable = ctx.invadable;
  final stalledExpansion = ctx.stalledExpansion;
  final declaredWarTargetFactionId = ctx.declaredWarTargetFactionId;
  final phasePlanInvadableIsAuthoritative =
      ctx.phasePlanInvadableIsAuthoritative;
  final nwInvasionWeight = ctx.nwInvasionWeight;
  final oldWorldInvasionWeight = ctx.oldWorldInvasionWeight;

  final destOwner = provinceOwner[move.destinationProvinceId] ?? '';
  final isNwInvadableDestination = snapshot
      .colonial
      .invadableNewWorldProvinceIdsSorted
      .contains(move.destinationProvinceId);
  if (phasePlanInvadableIsAuthoritative &&
      !invadable.contains(move.destinationProvinceId)) {
    // Stalled-expansion allowance (Refs #2509): own-territory marches stay
    // scoreable even when the phase plan's invadable set is authoritative,
    // so a stuck capital field army can march one province toward the
    // at-war frontier this turn and invade on the next. Foreign non-invadable
    // destinations (other GP, NW under EXPAND, etc.) remain blocked here —
    // the relaxation does not introduce any new declare-war / NW behavior.
    final ownMarchPermitted = stalledExpansion && destOwner == nationId;
    if (!ownMarchPermitted) {
      return 0;
    }
  }
  final destRegion = ProvinceId.regionIdFrom(move.destinationProvinceId);
  final destLocal = ProvinceId.localIdFrom(move.destinationProvinceId);
  final destNeighborLocals = neighborProvinceIdsInRegion(
    topology,
    destRegion,
    destLocal,
  );
  var score = 1.0;
  if (stalledExpansion) {
    final delta = _stalledExpansionArmyMoveScoreDelta(
      _StalledExpansionArmyMoveScoreDeltaInput(
        move: move,
        nationId: nationId,
        game: game,
        topology: topology,
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        invadable: invadable,
        destOwner: destOwner,
        destRegion: destRegion,
        destNeighborLocals: destNeighborLocals,
        declaredWarTargetFactionId: declaredWarTargetFactionId,
      ),
    );
    if (delta < 0) {
      score *= 0.05;
    } else {
      score += conquestOldWorldArmyMoveScaledBonus(
        baseBonus: delta,
        oldWorldInvasionWeight: oldWorldInvasionWeight,
      );
    }
  } else if (declaredWarTargetFactionId != null &&
      destOwner == declaredWarTargetFactionId) {
    score += conquestOldWorldArmyMoveScaledBonus(
      baseBonus: 50,
      oldWorldInvasionWeight: oldWorldInvasionWeight,
    );
  } else {
    final rel = getRelation(game, nationId, destOwner);
    if (rel != null && rel.atWar) {
      score += conquestOldWorldArmyMoveScaledBonus(
        baseBonus: kMovePreferEnemyTerritoryBonus.toDouble(),
        oldWorldInvasionWeight: oldWorldInvasionWeight,
      );
    }
  }
  if (invadable.contains(move.destinationProvinceId) &&
      !isNwInvadableDestination) {
    score += conquestOldWorldArmyMoveScaledBonus(
      baseBonus: 10,
      oldWorldInvasionWeight: oldWorldInvasionWeight,
    );
  }
  if (snapshot.colonial.invadableNewWorldProvinceIdsSorted.contains(
    move.destinationProvinceId,
  )) {
    if (nwInvasionWeight <= 0.0) {
      return 0;
    }
    score += conquestNwInvadableArmyMoveBonus(
      belowQuota: isBelowObserverConquestQuota(
        snapshot.conquest.oldWorldProvincesOwned,
      ),
      nwInvasionWeight: nwInvasionWeight,
    );
  }
  if (snapshot.conquest.adjacentOwnerFactionIdsSorted.contains(destOwner)) {
    score += conquestOldWorldArmyMoveScaledBonus(
      baseBonus: 8,
      oldWorldInvasionWeight: oldWorldInvasionWeight,
    );
  }
  for (final inv in snapshot.conquest.invadableProvinceIdsSorted) {
    if (ProvinceId.regionIdFrom(inv) != destRegion) {
      continue;
    }
    if (destNeighborLocals.contains(ProvinceId.localIdFrom(inv))) {
      score += conquestOldWorldArmyMoveScaledBonus(
        baseBonus: kConquestArmyMoveAdjacentInvadableBonus.toDouble(),
        oldWorldInvasionWeight: oldWorldInvasionWeight,
      );
      break;
    }
  }
  return score;
}
