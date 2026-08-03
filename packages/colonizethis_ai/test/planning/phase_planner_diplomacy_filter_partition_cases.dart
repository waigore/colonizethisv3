// Case bodies: phase-suppression partition pin (Refs #4239 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_diplomacy_filter_fixtures.dart';

void registerPhasePlannerDiplomacyFilterPartitionCases() {
  group('phase-suppression resolver partition', () {
    test('exactly one of the three phase-suppression resolvers returns true '
        'for EXPAND, COLONIAL-lite, and DEVELOP', () {
      // Partition pin: the three sibling resolvers
      // (`...DevelopSuppressionActive`,
      // `...ColonialLiteSuppressionActive`,
      // `...ExpandColonialSuppressionActive`) divide the four
      // ObserverGoalPhase values into a strict partition. EXPAND,
      // COLONIAL-lite, and DEVELOP each activate exactly one resolver;
      // COLONIAL activates none of the three (declare-war candidates
      // score normally under COLONIAL — the colonialPressure exception
      // in _declareWarSuppressedWarConcentrationScore handles
      // tribe-target preservation there). A regression where two
      // resolvers fire simultaneously would fold suppression branches
      // into each other and over-collapse candidates; a regression
      // where none fires under EXPAND/COLONIAL-lite/DEVELOP would
      // re-enable scoring branches the SPEC explicitly suppresses.
      for (final phase in <ObserverGoalPhase>[
        ObserverGoalPhase.expand,
        ObserverGoalPhase.colonialLite,
        ObserverGoalPhase.develop,
      ]) {
        final outcome = PhasePlanOutcome(phase: phase);
        final develop = resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
          phasePlan: outcome,
        );
        final colonialLite =
            resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
              phasePlan: outcome,
            );
        final expand =
            resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
              phasePlan: outcome,
            );
        final activeCount = [
          develop,
          colonialLite,
          expand,
        ].where((b) => b).length;
        expect(
          activeCount,
          1,
          reason:
              '$phase: partition contract requires exactly one of the '
              'three phase-suppression resolvers to return true '
              '(develop=$develop, colonialLite=$colonialLite, '
              'expandColonial=$expand).',
        );
      }
    });

    test(
      'all three phase-suppression resolvers return false under COLONIAL',
      () {
        // COLONIAL declare-war candidates score normally — the
        // `colonialPressure && ownsInvadableNw` exception in
        // _declareWarSuppressedWarConcentrationScore handles tribe-target
        // preservation. A regression where any of the three suppression
        // resolvers fires under COLONIAL would prematurely collapse
        // declare-war candidates and break the
        // `planColonialAcquisition` step 3 "declareWar + invade" path.
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
        expect(
          resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
            phasePlan: outcome,
          ),
          isFalse,
          reason:
              'COLONIAL must not activate the DEVELOP suppression resolver.',
        );
        expect(
          resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive(
            phasePlan: outcome,
          ),
          isFalse,
          reason:
              'COLONIAL must not activate the COLONIAL-lite suppression '
              'resolver.',
        );
        expect(
          resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive(
            phasePlan: outcome,
          ),
          isFalse,
          reason: 'COLONIAL must not activate the EXPAND suppression resolver.',
        );
      },
    );
  });
}
