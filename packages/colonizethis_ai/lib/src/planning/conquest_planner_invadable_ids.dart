import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'goal_manager.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'planner_context.dart';
import 'planning_helpers.dart'
    show colonialPressureScaleFromWeight, isAtWarWithAnyGreatPower;
import 'planning_imports.dart';

Set<String> legacyInvadableProvinceIds({
  required Game game,
  required AIWorldSnapshot snapshot,
  required bool structuralNewWorldSuppressed,
  double? nwInvasionWeightFromPhasePlan,
}) {
  final nwInvasionWeight =
      nwInvasionWeightFromPhasePlan ??
      (shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
            snapshot: snapshot,
            game: game,
          )
          ? 0.0
          : 1.0);
  return {
    ...snapshot.conquest.invadableProvinceIdsSorted,
    if (!structuralNewWorldSuppressed && nwInvasionWeight > 0.0)
      ...snapshot.colonial.invadableNewWorldProvinceIdsSorted,
  };
}

Set<String> invadableProvinceIdsForConquestPass({
  required Game game,
  required AIWorldSnapshot snapshot,
  PhasePlanOutcome? phasePlan,
  PhaseConquestInvadableResolution? conquestResolution,
}) {
  if (phasePlan == null) {
    return legacyInvadableProvinceIds(
      game: game,
      snapshot: snapshot,
      structuralNewWorldSuppressed: false,
    );
  }
  final resolution =
      conquestResolution ??
      resolvePhaseConquestInvadable(
        phasePlan: phasePlan,
        snapshot: snapshot,
        game: game,
      );
  final nwInvasionWeightFromPhasePlan = resolvePhaseConquestNwInvasionWeight(
    phasePlan: phasePlan,
  );
  if (resolution.useLegacyInvadable) {
    return legacyInvadableProvinceIds(
      game: game,
      snapshot: snapshot,
      structuralNewWorldSuppressed: resolution.structuralNewWorldSuppressed,
      nwInvasionWeightFromPhasePlan: nwInvasionWeightFromPhasePlan,
    );
  }
  return resolution.phasePlanInvadableSorted.toSet();
}

/// Invasion army moves after same-turn declare war. SPEC/ai/ai-architecture.md.
/// Resolves the military-economy weight floor for a conquest army-move pass
/// (Refs #3977 AC6). Behaviour-preserving extraction from
/// [runConquestArmyMovePlanner].
int resolveConquestArmyMoveWeight({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required bool stalledExpansion,
  required bool colonialPressureActive,
  required PhasePlanOutcome? phasePlan,
}) {
  var weight = ctx.resolveMilitaryEconomyWeight();
  final provincesToVictory = snapshot.conquest.provincesToVictory;
  if (ctx.primaryGoal == StrategicGoal.conquer || provincesToVictory > 10) {
    weight = weight < 10 ? 10 : weight;
  }
  if (provincesToVictory > kConquerScoreFloorProvincesToVictoryThreshold &&
      weight < 10) {
    weight = 10;
  }
  final atWarWithInvadableTarget =
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      snapshot.threats.atWarWith.isNotEmpty;
  if (stalledExpansion &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < 90) {
    weight = 90;
  } else if (stalledExpansion && atWarWithInvadableTarget && weight < 80) {
    weight = 80;
  }
  if (stalledExpansion && weight < kConquestArmyMoveMinWeightWhenStalled) {
    weight = kConquestArmyMoveMinWeightWhenStalled;
  }
  if (snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      !isAtWarWithAnyGreatPower(ctx.game, snapshot) &&
      weight < kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar) {
    weight = kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar;
  }
  // Refs #2847 Phase 3 conquest colonial-pressure floor wiring: source
  // the floor magnitude from the soft-phase NW acquisition weight on the
  // dispatched phase plan instead of the legacy hard
  // `kConquestArmyMoveMinWeightWhenColonialPressure` floor. The null-phase-plan
  // fallback maps the legacy boolean (`colonialPressureActive`) to
  // `1.0 / 0.0` so callers without a `PhasePlanOutcome` preserve
  // pre-Phase-3 behaviour exactly. At the early-sprint default curve
  // (`newWorldAcquisition = 0.05` for OW <= 7) the floor collapses to
  // `round(45 * 0.05) = 2`, well below the stalled-expansion floors so
  // the OW conquest sprint is not dominated by colonial-pressure pulls.
  final colonialPressureWeight = colonialPressureScaleFromWeight(
    colonialPressureWeight: phasePlan != null
        ? resolvePhaseConquestColonialPressureWeight(phasePlan: phasePlan)
        : null,
    legacyColonialPressureActive: colonialPressureActive,
  );
  final colonialPressureFloor = conquestColonialPressureMinWeightFloor(
    colonialPressureWeight: colonialPressureWeight,
  );
  if (weight < colonialPressureFloor) {
    weight = colonialPressureFloor;
  }
  return weight;
}

