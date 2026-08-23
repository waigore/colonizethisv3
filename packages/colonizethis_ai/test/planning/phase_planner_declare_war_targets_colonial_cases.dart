// Cases for phase_planner_declare_war_targets_test.dart (Refs #4602).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_declare_war_targets.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart';
import 'package:colonizethis_test/test.dart';

const PhasePriorityWeights kDeclareWarTargetsNwAcquisitionZeroExpand =
    PhasePriorityWeights(
      oldWorldConquest: 0.95,
      newWorldAcquisition: 0.0,
      oldWorldCivilian: 0.90,
      newWorldCivilian: 0.10,
    );

void registerPhasePlannerDeclareWarTargetsColonialCases() {
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

    test('EXPAND with newWorldAcquisition=0 surfaces null even when '
        'acquisition target is non-null', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribe4',
          method: AcquisitionMethod.declareWar,
        ),
        priorityWeights: kDeclareWarTargetsNwAcquisitionZeroExpand,
      );
      expect(gpColonialDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('EXPAND with newWorldAcquisition>0 surfaces declareWar target '
        '(Refs #2847)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribe4',
          method: AcquisitionMethod.declareWar,
        ),
      );
      expect(gpColonialDeclareWarTargetFromPhasePlan(outcome), 'tribe4');
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
}
