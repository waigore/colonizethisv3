// Cases for phase_planner_declare_war_targets_test.dart (Refs #4602).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_declare_war_targets.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_test/test.dart';

void registerPhasePlannerDeclareWarTargetsExclusionCases() {
  group('adapter mutual exclusion', () {
    test('EXPAND surfaces only the EXPAND adapter target', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandDeclareWarTargetFactionId: 'minorE',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), 'minorE');
      expect(gpColonialDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('COLONIAL surfaces only the COLONIAL adapter target', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribeC',
          method: AcquisitionMethod.declareWar,
        ),
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
      expect(gpColonialDeclareWarTargetFromPhasePlan(outcome), 'tribeC');
    });

    test('COLONIAL-lite surfaces only the EXPAND adapter target', () {
      // The COLONIAL-lite safeguard runs EXPAND alongside its overture /
      // naval directives; no NW declareWar surfaces because acquisition
      // is structurally suppressed.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandDeclareWarTargetFactionId: 'minorL',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), 'minorL');
      expect(gpColonialDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('DEVELOP surfaces neither adapter target', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        expandDeclareWarTargetFactionId: 'minorD',
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribeD',
          method: AcquisitionMethod.declareWar,
        ),
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
      expect(gpColonialDeclareWarTargetFromPhasePlan(outcome), isNull);
    });
  });

  group('determinism (Must-have #7)', () {
    test('gpExpandDeclareWarTargetFromPhasePlan stable across calls', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandDeclareWarTargetFactionId: 'minorStable',
      );
      expect(
        gpExpandDeclareWarTargetFromPhasePlan(outcome),
        gpExpandDeclareWarTargetFromPhasePlan(outcome),
      );
    });

    test('gpColonialDeclareWarTargetFromPhasePlan stable across calls', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribeStable',
          method: AcquisitionMethod.declareWar,
        ),
      );
      expect(
        gpColonialDeclareWarTargetFromPhasePlan(outcome),
        gpColonialDeclareWarTargetFromPhasePlan(outcome),
      );
    });
  });
}
