/// Phase-planner peace-target extraction for orchestrator wiring (Refs #2509 S5).
///
/// Maps a [PhasePlanOutcome] from [runPhasePlanners] to the sorted GP peace
/// target list the diplomacy planner should `offerPeace` toward this turn.
/// Used by `domain_planner_orchestrator.dart` on every player turn since the
/// S5 orchestrator wiring landed — `_stalledPeacePlannerResultIfNeeded`
/// reads [gpPeaceTargetsFromPhasePlan] in place of the legacy
/// `collectStalledGreatPowerPeaceTargets` whenever a `phasePlan` is
/// threaded through (the canonical post-S5 path).
/// `collectStalledGreatPowerPeaceTargets` is retained at its canonical
/// home in `observer_goal_phase.dart` as the no-`phasePlan` fallback for
/// the unit-test fixtures that still construct orchestrator state without
/// the dispatched phase plan; the legacy
/// `diplomacy_planner_peace_targets.dart` host was deleted in S1.
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns the phase-specific Great Power peace targets for [outcome].
///
/// EXPAND and COLONIAL-lite use [PhasePlanOutcome.expandPeaceTargetFactionIdsSorted].
/// COLONIAL uses [PhasePlanOutcome.colonialPeaceTargetFactionIdsSorted].
/// DEVELOP uses [PhasePlanOutcome.developPeaceTargetFactionIdsSorted].
///
/// The list is already ascending-sorted by the underlying planner functions.
List<String> gpPeaceTargetsFromPhasePlan(PhasePlanOutcome outcome) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
      return outcome.expandPeaceTargetFactionIdsSorted;
    case ObserverGoalPhase.colonial:
      return outcome.colonialPeaceTargetFactionIdsSorted;
    case ObserverGoalPhase.develop:
      return outcome.developPeaceTargetFactionIdsSorted;
  }
}

/// Returns the phase-specific minor / tribe distraction peace targets for
/// [outcome] (Refs #2847 § H5).
///
/// EXPAND and COLONIAL-lite surface
/// [PhasePlanOutcome.expandDistractionPeaceTargetFactionIdsSorted] — the
/// below-quota regiment-thin minor / tribe distraction `offerPeace` set
/// that the Great-Power-only [gpPeaceTargetsFromPhasePlan] adapter does
/// not carry. COLONIAL and DEVELOP have no distraction-peace concept in
/// the phase plan and return `const []` (their peace decisions are
/// covered by `colonialPeaceTargetFactionIdsSorted` /
/// `developPeaceTargetFactionIdsSorted`).
///
/// The diplomacy planner unions this with [gpPeaceTargetsFromPhasePlan]
/// so the production phase-plan path emits the same distraction peace the
/// no-`phasePlan` `collectStalledGreatPowerPeaceTargets` fallback carries
/// (restoring the path that regressed when the S5 GP-only EXPAND peace
/// adapter took over; Refs #2509 S5, #2847 § H5). The list is already
/// ascending-sorted and de-duplicated by the dispatcher.
List<String> distractionPeaceTargetsFromPhasePlan(PhasePlanOutcome outcome) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
      return outcome.expandDistractionPeaceTargetFactionIdsSorted;
    case ObserverGoalPhase.colonial:
    case ObserverGoalPhase.develop:
      return const <String>[];
  }
}

/// Below-quota peer-stalled GP peace absent from the GP-only `planExpandPeace`
/// adapter (Refs #2847 § H6).
///
/// Scoped to [belowQuotaPeerGpPeaceTargets] only — the seed-42 gp5↔gp6
/// mutual-plateau distraction pivot. Broader
/// [expandRatchetGreatPowerPeaceTargets] and full
/// [collectStalledGreatPowerPeaceTargets] unions regressed the gp4 +3 / gp6
/// +10 baselines held by H5 (H6 verification).
List<String> belowQuotaPeerGpPeaceTargetsForProduction({
  required Game game,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
}) {
  switch (phasePlan.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
      return belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot);
    case ObserverGoalPhase.colonial:
    case ObserverGoalPhase.develop:
      return const <String>[];
  }
}

/// Returns the sorted union of production diplomacy peace targets when a
/// [PhasePlanOutcome] is threaded through (Refs #2847 § H6).
///
/// Unions the phase-plan GP peace adapter, the H5 distraction slot, and the
/// below-quota peer-stalled GP peace pivot that the post-S5 `planExpandPeace`
/// adapter alone dropped from the production path.
List<String> productionPeaceTargetsFromPhasePlan({
  required Game game,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
}) {
  return <String>{
    ...gpPeaceTargetsFromPhasePlan(phasePlan),
    ...distractionPeaceTargetsFromPhasePlan(phasePlan),
    ...belowQuotaPeerGpPeaceTargetsForProduction(
      game: game,
      snapshot: snapshot,
      phasePlan: phasePlan,
    ),
  }.toList()
    ..sort();
}
