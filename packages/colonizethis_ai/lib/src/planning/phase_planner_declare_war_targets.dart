/// Phase-planner declare-war target extraction for orchestrator wiring
/// (Refs #2509 S5 slice — companion to `phase_planner_peace_targets.dart`).
///
/// Maps a [PhasePlanOutcome] from [runPhasePlanners] to the GP / minor / tribe
/// `factionId` the diplomacy planner should `declareWar` against this turn.
/// Two adapters are exposed because the issue spec splits declare-war picks
/// between the EXPAND and COLONIAL phases:
///
///   - [gpExpandDeclareWarTargetFromPhasePlan] returns the EXPAND
///     declare-war factionId from `planExpandDeclareWar`. The same target is
///     surfaced under [ObserverGoalPhase.colonialLite] because the OW push
///     keeps running during the COLONIAL-lite safeguard (issue #2509
///     § COLONIAL-lite: "Begin NW overture/naval penetration without
///     weakening OW push"). `null` for [ObserverGoalPhase.colonial] and
///     [ObserverGoalPhase.develop] — by spec those phases never declare-war
///     on a GP for OW conquest.
///
///   - [gpColonialDeclareWarTargetFromPhasePlan] returns the COLONIAL
///     declare-war factionId from `planColonialAcquisition` **only** when the
///     resolved acquisition method is [AcquisitionMethod.declareWar]. For
///     `joinEmpire`, `purchase_land`, or `null` acquisitions the adapter
///     returns `null` so the diplomacy / military / naval pair fall back to
///     the at-war arm without forcing a fresh declareWar. The adapter
///     returns `null` for all non-COLONIAL phases (EXPAND, COLONIAL-lite,
///     DEVELOP) because [PhasePlanOutcome.colonialAcquisitionTarget] is
///     structurally suppressed outside [ObserverGoalPhase.colonial] per
///     `SPEC/ai/phase-planner-dispatch.md` § Suppression matrix.
///
/// Both helpers are pure functions of the [PhasePlanOutcome] alone and never
/// re-invoke the underlying planners; the orchestrator pays the planner
/// cost once via [runPhasePlanners] and consumes the adapters' outputs
/// repeatedly. Identical inputs always yield identical outputs (Refs #2509
/// Must-have #7 determinism).
library;

import 'colonial_phase_planner.dart' show AcquisitionMethod;
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns the EXPAND-phase declare-war factionId for [outcome], or `null`
/// when no GP-level OW declare-war pick is authorised in the active phase.
///
/// EXPAND and COLONIAL-lite both surface `expandDeclareWarTargetFactionId`
/// (which may itself be `null` if `planExpandDeclareWar` exhausted its
/// priority arms). COLONIAL and DEVELOP always return `null` because the
/// phase planner architecture structurally moves declare-war picks for
/// those phases into `planColonialAcquisition` (see
/// [gpColonialDeclareWarTargetFromPhasePlan]).
String? gpExpandDeclareWarTargetFromPhasePlan(PhasePlanOutcome outcome) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
      return outcome.expandDeclareWarTargetFactionId;
    case ObserverGoalPhase.colonial:
    case ObserverGoalPhase.develop:
      return null;
  }
}

/// Returns the COLONIAL-phase declare-war factionId for [outcome], or
/// `null` when the active phase / acquisition method does not authorise a
/// fresh declareWar this turn.
///
/// Only [ObserverGoalPhase.colonial] outcomes whose
/// [PhasePlanOutcome.colonialAcquisitionTarget] resolved to
/// [AcquisitionMethod.declareWar] return a non-null factionId; every other
/// case returns `null`:
///   - `joinEmpire` and `purchase_land` acquisitions resolve via the
///     diplomacy / build pipelines without a declareWar.
///   - A `null` acquisition target means no acquisition arm fired this
///     turn; the military / naval pair fall back to the at-war arm.
///   - Non-COLONIAL phases never populate `colonialAcquisitionTarget`
///     (suppression matrix), so this adapter returns `null` structurally.
String? gpColonialDeclareWarTargetFromPhasePlan(PhasePlanOutcome outcome) {
  if (outcome.phase != ObserverGoalPhase.colonial) {
    return null;
  }
  final target = outcome.colonialAcquisitionTarget;
  if (target == null || target.method != AcquisitionMethod.declareWar) {
    return null;
  }
  return target.targetFactionId;
}
