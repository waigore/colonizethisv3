// Pins the structural contract of the shared phase-filter colonial-pressure
// helper [phaseColonialPressureActiveFromPlan] (Refs #3749 step 4 —
// phase-filter family dedup).
//
// The helper is the single source of truth for the `PhasePlanOutcome` →
// COLONIAL-only colonial-pressure projection that the conquest, diplomacy, and
// economy phase filters previously each duplicated inline as
// `resolvePhaseColonialPressureActive(phasePlan.phase)`. These tests assert:
//   - positive: `true` only under `ObserverGoalPhase.colonial`;
//   - negative: `false` for EXPAND / COLONIAL-lite / DEVELOP;
//   - behaviour-preservation: each per-family filter wrapper now delegates to
//     the shared helper and therefore agrees with it for every phase.
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_filter_common.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('phaseColonialPressureActiveFromPlan', () {
    test('is true only under ObserverGoalPhase.colonial', () {
      expect(
        phaseColonialPressureActiveFromPlan(
          phasePlan: const PhasePlanOutcome(phase: ObserverGoalPhase.colonial),
        ),
        isTrue,
      );
    });

    test('is false for every non-COLONIAL phase', () {
      for (final phase in ObserverGoalPhase.values) {
        if (phase == ObserverGoalPhase.colonial) continue;
        expect(
          phaseColonialPressureActiveFromPlan(
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isFalse,
          reason: 'colonial pressure must be structurally inactive for $phase',
        );
      }
    });

    test('is deterministic for a fixed phase plan', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      final first = phaseColonialPressureActiveFromPlan(phasePlan: outcome);
      final second = phaseColonialPressureActiveFromPlan(phasePlan: outcome);
      expect(first, equals(second));
    });
  });

  group('per-family wrappers delegate to the shared helper', () {
    test('conquest / diplomacy / economy agree with the shared helper for '
        'every phase', () {
      for (final phase in ObserverGoalPhase.values) {
        final outcome = PhasePlanOutcome(phase: phase);
        final shared = phaseColonialPressureActiveFromPlan(phasePlan: outcome);
        expect(
          resolvePhaseConquestColonialPressureActive(phasePlan: outcome),
          equals(shared),
          reason: 'conquest wrapper must match shared helper for $phase',
        );
        expect(
          resolvePhaseDiplomacyDeclareWarColonialPressureActive(
            phasePlan: outcome,
          ),
          equals(shared),
          reason: 'diplomacy wrapper must match shared helper for $phase',
        );
        expect(
          resolvePhaseEconomyColonialPressureActive(phasePlan: outcome),
          equals(shared),
          reason: 'economy wrapper must match shared helper for $phase',
        );
      }
    });
  });
}
