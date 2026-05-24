// Unit tests for `phase_planner_declare_war_targets.dart`
// (Refs #2509 S5 orchestrator adapter slice).
//
// Adapter contract pinned here (from
// `SPEC/ai/phase-planner-dispatch.md` § Adapter helpers):
//
//   gpExpandDeclareWarTargetFromPhasePlan(outcome):
//     - EXPAND       -> outcome.expandDeclareWarTargetFactionId
//     - COLONIAL-lite -> outcome.expandDeclareWarTargetFactionId
//       (OW push keeps running during the safeguard)
//     - COLONIAL     -> null
//     - DEVELOP      -> null
//
//   gpColonialDeclareWarTargetFromPhasePlan(outcome):
//     - COLONIAL with acquisition method == declareWar
//                    -> outcome.colonialAcquisitionTarget.targetFactionId
//     - COLONIAL with acquisition method == joinEmpire / purchaseLand
//                    -> null
//     - COLONIAL with null acquisition target
//                    -> null
//     - EXPAND / COLONIAL-lite / DEVELOP
//                    -> null (structural; colonialAcquisitionTarget is
//                            suppressed outside COLONIAL by the dispatcher)
//
// Fixtures here construct `PhasePlanOutcome` instances directly so the
// tests do not require a `Game` / `AIWorldSnapshot` pair. Outcome
// composition from real `runPhasePlanners` dispatches is already covered
// by `phase_planner_dispatch_test.dart`.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_declare_war_targets.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('gpExpandDeclareWarTargetFromPhasePlan', () {
    test('EXPAND surfaces expandDeclareWarTargetFactionId', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandDeclareWarTargetFactionId: 'minor1',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), 'minor1');
    });

    test('EXPAND null target surfaces null', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('COLONIAL-lite surfaces expandDeclareWarTargetFactionId', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandDeclareWarTargetFactionId: 'minor2',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), 'minor2');
    });

    test('COLONIAL-lite null target surfaces null', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('COLONIAL returns null even when expand slot non-null', () {
      // Defensive: the dispatcher never populates expand slots in COLONIAL,
      // but the adapter must short-circuit on phase regardless so a
      // future regression in the dispatcher does not leak an EXPAND
      // declare-war target into the COLONIAL diplomacy pass.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandDeclareWarTargetFactionId: 'minor3',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('DEVELOP returns null even when expand slot non-null', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        expandDeclareWarTargetFactionId: 'minor4',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('defaultExpand outcome surfaces null', () {
      expect(
        gpExpandDeclareWarTargetFromPhasePlan(PhasePlanOutcome.defaultExpand),
        isNull,
      );
    });

    test('defaultColonialLite outcome surfaces null', () {
      expect(
        gpExpandDeclareWarTargetFromPhasePlan(
          PhasePlanOutcome.defaultColonialLite,
        ),
        isNull,
      );
    });

    test('defaultColonial outcome surfaces null', () {
      expect(
        gpExpandDeclareWarTargetFromPhasePlan(PhasePlanOutcome.defaultColonial),
        isNull,
      );
    });

    test('defaultDevelop outcome surfaces null', () {
      expect(
        gpExpandDeclareWarTargetFromPhasePlan(PhasePlanOutcome.defaultDevelop),
        isNull,
      );
    });
  });

  group('gpColonialDeclareWarTargetFromPhasePlan', () {
    test('COLONIAL + declareWar method surfaces targetFactionId', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribe1',
          method: AcquisitionMethod.declareWar,
        ),
      );
      expect(gpColonialDeclareWarTargetFromPhasePlan(outcome), 'tribe1');
    });

    test('COLONIAL + joinEmpire method surfaces null', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribe2',
          method: AcquisitionMethod.joinEmpire,
        ),
      );
      expect(
        gpColonialDeclareWarTargetFromPhasePlan(outcome),
        isNull,
        reason:
            'Join Empire acquisitions resolve via establishOverture, not '
            'declareWar; the adapter must surface null so the diplomacy '
            'planner does not declare war when the acquisition path is '
            'peaceful.',
      );
    });

    test('COLONIAL + purchaseLand method surfaces null', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribe3',
          method: AcquisitionMethod.purchaseLand,
        ),
      );
      expect(
        gpColonialDeclareWarTargetFromPhasePlan(outcome),
        isNull,
        reason:
            'purchase_land acquisitions resolve via the build pipeline, '
            'not declareWar.',
      );
    });

    test('COLONIAL + null acquisition target surfaces null', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        gpColonialDeclareWarTargetFromPhasePlan(outcome),
        isNull,
        reason:
            'Null acquisition means no method fired this turn; the '
            'military / naval pair fall back to the at-war arm without a '
            'fresh declareWar.',
      );
    });

    test('EXPAND surfaces null even when acquisition target is non-null', () {
      // Defensive: the dispatcher never populates colonialAcquisitionTarget
      // in EXPAND, but the adapter must short-circuit on phase to defend
      // the suppression matrix.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribe4',
          method: AcquisitionMethod.declareWar,
        ),
      );
      expect(gpColonialDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test(
      'COLONIAL-lite surfaces null even when acquisition target is non-null',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonialLite,
          colonialAcquisitionTarget: ColonialAcquisitionTarget(
            targetFactionId: 'tribe5',
            method: AcquisitionMethod.declareWar,
          ),
        );
        expect(
          gpColonialDeclareWarTargetFromPhasePlan(outcome),
          isNull,
          reason:
              'COLONIAL-lite is the EXPAND safeguard that suppresses NW '
              'declareWar / joinEmpire / purchase_land. Even if a future '
              'regression populated colonialAcquisitionTarget under the '
              'safeguard, the adapter must keep returning null.',
        );
      },
    );

    test('DEVELOP surfaces null even when acquisition target is non-null', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribe6',
          method: AcquisitionMethod.declareWar,
        ),
      );
      expect(gpColonialDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('defaultColonial outcome surfaces null', () {
      expect(
        gpColonialDeclareWarTargetFromPhasePlan(
          PhasePlanOutcome.defaultColonial,
        ),
        isNull,
      );
    });

    test('defaultExpand outcome surfaces null', () {
      expect(
        gpColonialDeclareWarTargetFromPhasePlan(PhasePlanOutcome.defaultExpand),
        isNull,
      );
    });
  });

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
