/// Phase-planner conquest destination filter for orchestrator wiring
/// (Refs #2509 S5 slice — companion to `phase_planner_military_plans.dart`).
///
/// Resolves which invadable province ids `runConquestArmyMovePlanner` may
/// consider this turn from a single [PhasePlanOutcome]. When a non-default
/// [ExpandMilitaryPlan] or [ColonialMilitaryPlan] is active, the conquest
/// pass restricts to that plan's `priorityDestinationProvinceIdsSorted`
/// instead of the legacy union of OW invadable plus optionally NW invadable.
/// When both military adapters return default plans, the resolution falls
/// back to the legacy invadable set with optional structural NW suppression
/// under EXPAND / COLONIAL-lite (issue #2509 § EXPAND NW suppression).
/// DEVELOP routes to [PhaseConquestInvadableResolution.skipConquestPass]
/// because the phase planner emits no invasion army moves (issue #2509 §
/// DEVELOP suppressions).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'colonial_phase_planner.dart' show ColonialMilitaryPlan;
import 'expand_phase_planner.dart' show ExpandMilitaryPlan;
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_conquest_filter_weights.dart';
import 'phase_planner_military_plans.dart';
import 'phase_priority_weights.dart' show isNwLockRecoveryPathEActive;
import 'planning_helpers.dart' show resolveFromPhasePlan;

export 'phase_planner_conquest_filter_weights.dart';

/// Outcome of [resolvePhaseConquestInvadable] for one player turn.
class PhaseConquestInvadableResolution {
  const PhaseConquestInvadableResolution({
    this.useLegacyInvadable = false,
    this.phasePlanInvadableSorted = const <String>[],
    this.structuralNewWorldSuppressed = false,
    this.skipConquestPass = false,
  });

  /// When `true`, callers build the invadable set from
  /// [ConquestSummary] / [ColonialSummary] using the legacy path.
  /// When `false`, [phasePlanInvadableSorted] is authoritative.
  final bool useLegacyInvadable;

  /// Non-empty only when [useLegacyInvadable] is `false`.
  final List<String> phasePlanInvadableSorted;

  /// When [useLegacyInvadable] is `true`, exclude NW invadable provinces
  /// from the legacy union when [resolvePhaseConquestNwInvasionWeight] is
  /// `<= 0.0` for the active [PhasePlanOutcome] (Refs #2847 Phase 3).
  final bool structuralNewWorldSuppressed;

  /// When `true`, `runConquestArmyMovePlanner` returns without emitting
  /// orders (DEVELOP phase).
  final bool skipConquestPass;
}

/// True when [playerId] has at least one non-Home field army with regiments
/// stationed in [regionId] (Refs #2924 Path E NW conquest feasibility).
bool playerHasNonHomeFieldArmyInRegion({
  required Game game,
  required String playerId,
  required String regionId,
}) {
  for (final army in game.worldState.armies) {
    if (army.ownerId != playerId || army.isHomeArmy) continue;
    if (army.regimentUnitIds.isEmpty) continue;
    if (ProvinceId.regionIdFrom(army.stationedProvinceId) == regionId) {
      return true;
    }
  }
  return false;
}

/// Resolves the conquest destination filter for [phasePlan].
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7).
PhaseConquestInvadableResolution resolvePhaseConquestInvadable({
  required PhasePlanOutcome phasePlan,
  AIWorldSnapshot? snapshot,
  Game? game,
}) {
  final nwInvasionWeight = resolvePhaseConquestNwInvasionWeight(
    phasePlan: phasePlan,
  );
  return resolveFromPhasePlan(
    phasePlan: phasePlan,
    // Legacy-invadable fallback when no phase / phase-plan arm fires below.
    defaultResolution: PhaseConquestInvadableResolution(
      useLegacyInvadable: true,
      structuralNewWorldSuppressed: nwInvasionWeight <= 0.0,
    ),
    project: (plan) {
      if (plan.phase == ObserverGoalPhase.develop) {
        return const PhaseConquestInvadableResolution(skipConquestPass: true);
      }

      final expandPlan = expandMilitaryPlanFromPhasePlan(plan);
      final colonialPlan = colonialMilitaryPlanFromPhasePlan(plan);

      final nwInvasionArmyMoveFeasible =
          game != null &&
          snapshot != null &&
          playerHasNonHomeFieldArmyInRegion(
            game: game,
            playerId: snapshot.playerId,
            regionId: kNewWorldRegionId,
          );

      final prioritizeColonialNwUnderLockRecovery =
          snapshot != null &&
          isNwLockRecoveryPathEActive(
            snapshot: snapshot,
            expandEconomyPlan: plan.expandEconomyPlan,
          ) &&
          colonialPlan.priorityDestinationProvinceIdsSorted.isNotEmpty &&
          nwInvasionArmyMoveFeasible;

      if (prioritizeColonialNwUnderLockRecovery) {
        return PhaseConquestInvadableResolution(
          phasePlanInvadableSorted:
              colonialPlan.priorityDestinationProvinceIdsSorted,
        );
      }

      if (expandPlan.priorityDestinationProvinceIdsSorted.isNotEmpty) {
        return PhaseConquestInvadableResolution(
          phasePlanInvadableSorted:
              expandPlan.priorityDestinationProvinceIdsSorted,
        );
      }

      if (colonialPlan.priorityDestinationProvinceIdsSorted.isNotEmpty) {
        return PhaseConquestInvadableResolution(
          phasePlanInvadableSorted:
              colonialPlan.priorityDestinationProvinceIdsSorted,
        );
      }

      return null;
    },
  );
}
