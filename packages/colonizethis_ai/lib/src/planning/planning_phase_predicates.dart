/// Soft-phase structural predicates and PhasePlanOutcome projections (Refs #3941).
library;

import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

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

/// Resolves a per-family phase-filter resolution from [phasePlan].
///
/// Single source of truth for the "project a non-default resolution from the
/// active [PhasePlanOutcome]; fall back to the family's [defaultResolution]
/// when no arm fires" skeleton repeated across the phase-filter Resolution
/// families ([resolvePhaseNavalDirective] in `phase_planner_naval_filter.dart`
/// and [resolvePhaseConquestInvadable] in `phase_planner_conquest_filter.dart`,
/// Refs #3717 phase-filter resolution-skeleton dedup). Each family supplies
/// only its own [project] callback (returning the populated resolution when a
/// phase / phase-plan arm applies, or `null` to defer) plus its
/// [defaultResolution]; the `project(...) ?? defaultResolution` fallback lives
/// once here.
///
/// Behaviour-preserving against the inline `if (...) return X; ... return
/// default;` chains it replaces: [project] is evaluated exactly once and its
/// non-null result is returned verbatim, otherwise [defaultResolution] is
/// returned, so results are byte-identical for a pure [project]. The generic
/// [T] keeps each family's concrete resolution type (no boxing / shared base
/// type) so callers retain full static typing.
///
/// Pure and deterministic — identical inputs (and a pure [project]) always
/// yield identical resolutions (Refs #2509 Must-have #7). Adds no scan cost
/// beyond the caller's own [project], consistent with
/// `colonizethis-turn-resolution-budget.mdc`.
T resolveFromPhasePlan<T>({
  required PhasePlanOutcome phasePlan,
  required T defaultResolution,
  required T? Function(PhasePlanOutcome phasePlan) project,
}) =>
    project(phasePlan) ?? defaultResolution;
