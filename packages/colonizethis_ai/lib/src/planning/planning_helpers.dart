/// Shared planning-layer helpers (Refs #3278 dedup).
///
/// Canonical home for small pure functions that were previously copy-pasted
/// inline across the phase-planner / filter modules:
///
///   - [gpFactionIdsAtWarWith] — the GP-only at-war filter that replaces the
///     `[for (final f in snapshot.threats.atWarWith) if (game.playerById(f)
///     != null) f]` comprehension repeated across the planners.
///   - [scaleWeightedBonus] — the `<= 0.0 → 0`, clamp-to-`1.0`, `round()`
///     weight-scaling idiom shared by the soft-phase bonus/floor resolvers.
///   - [resolvePhaseColonialPressureActive] /
///     [resolvePhaseExpandOrColonialLiteActive] — the structural phase
///     predicates shared by the conquest / economy / diplomacy / goal filters.
///   - [resolvePhaseNewWorldAcquisitionWeight] /
///     [resolvePhaseOldWorldConquestWeight] /
///     [resolvePhaseOldWorldCivilianWeight] /
///     [resolvePhaseNewWorldCivilianWeight] — the soft-phase
///     `PhasePlanOutcome` → `priorityWeights.<slot>` projections shared by the
///     conquest / naval / diplomacy / economy phase filters.
///
/// Keeping these in one place removes the duplication flagged by the
/// `repo.ai_dedup_gp_wars_filter` and `repo.ai_dedup_weight_scale_clamp`
/// repo-lint rules and preserves the existing deterministic behaviour exactly.
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns every Great Power the active player is currently at war with as a
/// new ascending-sorted `List<String>` of `factionId`s.
///
/// Filters [ThreatSummary.atWarWith] down to factions for which
/// [Game.playerById] returns a non-null [Player] — tribes and minor nations
/// are not [Player] entries and are therefore excluded. The result is sorted
/// ascending so callers see a stable order regardless of the iteration order
/// of [ThreatSummary.atWarWith] (the inline comprehensions this helper
/// replaces either sorted their output or used it only for
/// length / membership checks, so the sort is behaviour-preserving).
///
/// Pure and deterministic — identical inputs always yield identical lists
/// (Refs #2509 Must-have #7).
List<String> gpFactionIdsAtWarWith(Game game, AIWorldSnapshot snapshot) {
  return <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
}

/// Scales [baseConstant] by [weight] clamped to `[0.0, 1.0]`, returning the
/// rounded integer result.
///
/// Shared body of the soft-phase weight-scaling resolvers (Refs #2847 Phase 3
/// consumer wiring). Matches the prior inline idiom exactly:
///
///   - `weight <= 0.0` returns `0` (no bonus / floor applied).
///   - `weight >= 1.0` is clamped to `1.0`, returning `baseConstant` exactly.
///   - Intermediate weights return `round(baseConstant × weight)`.
///
/// The `<= 0.0` guard and `> 1.0` clamp boundaries are preserved verbatim from
/// the call sites so rounding semantics are identical.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
int scaleWeightedBonus(double weight, int baseConstant) {
  if (weight <= 0.0) {
    return 0;
  }
  final clamped = weight > 1.0 ? 1.0 : weight;
  return (baseConstant * clamped).round();
}

/// Structural predicate: `true` only under [ObserverGoalPhase.colonial].
///
/// Single source of truth for the colonial-pressure "active" gate shared by
/// the conquest, economy, diplomacy, and goal phase filters. Each filter's
/// public resolver delegates here so the `phase == ObserverGoalPhase.colonial`
/// comparison lives once.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
bool resolvePhaseColonialPressureActive(ObserverGoalPhase phase) =>
    phase == ObserverGoalPhase.colonial;

/// Structural predicate: `true` under [ObserverGoalPhase.expand] and
/// [ObserverGoalPhase.colonialLite] (the below-quota OW-expansion phases).
///
/// Single source of truth for the `phase == expand || phase == colonialLite`
/// gate shared by the conquest extra-passes resolver and the goal-filter
/// colonial-pressure suppression resolver. Both phases require
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` at entry.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
bool resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase phase) =>
    phase == ObserverGoalPhase.expand ||
    phase == ObserverGoalPhase.colonialLite;

/// Projects the soft-phase New-World-acquisition priority weight from
/// [phasePlan].
///
/// Single source of truth for the
/// `phasePlan.priorityWeights.newWorldAcquisition` projection shared by the
/// conquest, naval, diplomacy, and economy phase filters (Refs #3717
/// phase-filter weight-projection dedup). Each family's public weight resolver
/// delegates here so the `PhasePlanOutcome` → `priorityWeights` slot mapping
/// lives once, mirroring the existing [resolvePhaseColonialPressureActive] /
/// [scaleWeightedBonus] dedup. Reads only `phasePlan.priorityWeights` and never
/// inspects sibling slots.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
double resolvePhaseNewWorldAcquisitionWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.newWorldAcquisition;

/// Projects the soft-phase Old-World-conquest priority weight from [phasePlan].
///
/// Companion of [resolvePhaseNewWorldAcquisitionWeight]; single source of truth
/// for the `phasePlan.priorityWeights.oldWorldConquest` projection shared by the
/// conquest and diplomacy declare-war filters (Refs #3717).
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseOldWorldConquestWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.oldWorldConquest;

/// Projects the soft-phase Old-World-civilian priority weight from [phasePlan].
///
/// Companion of [resolvePhaseNewWorldAcquisitionWeight]; single source of truth
/// for the `phasePlan.priorityWeights.oldWorldCivilian` projection used by the
/// economy filter (Refs #3717).
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseOldWorldCivilianWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.oldWorldCivilian;

/// Projects the soft-phase New-World-civilian priority weight from [phasePlan].
///
/// Companion of [resolvePhaseNewWorldAcquisitionWeight]; single source of truth
/// for the `phasePlan.priorityWeights.newWorldCivilian` projection used by the
/// economy filter (Refs #3717).
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseNewWorldCivilianWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.newWorldCivilian;
