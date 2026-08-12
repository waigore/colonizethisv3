// Case bodies for `phase_planner_dispatch_test.dart` (Refs #4310 Slice D).
// COLONIAL-lite outcome composition.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';

void registerPhasePlannerDispatchColonialLiteCases() {
  group('COLONIAL-lite outcome composition', () {
    test('COLONIAL-lite populates EXPAND + COLONIAL-lite slots', () {
      final game = buildPhasePlannerDispatchColonialLiteGame();
      final snapshot = buildPhasePlannerDispatchColonialLiteSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      // EXPAND continues to run during the safeguard ("Begin NW
      // overture/naval penetration without weakening OW push").
      expect(
        outcome.expandDeclareWarTargetFactionId,
        planExpandDeclareWar(game: game, snapshot: snapshot),
      );
      expect(
        outcome.expandMilitaryPlan,
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: outcome.expandDeclareWarTargetFactionId,
        ),
      );

      // COLONIAL-lite directives surface.
      expect(
        outcome.colonialLiteOverturesSorted,
        planColonialLiteOvertures(game: game, snapshot: snapshot),
      );
      expect(
        outcome.colonialLiteNavalPlan,
        planColonialLiteNaval(game: game, snapshot: snapshot),
      );

      // Full-COLONIAL and DEVELOP slots stay default — COLONIAL-lite
      // is structurally an EXPAND safeguard, NOT a full-COLONIAL
      // run.
      expect(outcome.colonialAcquisitionTarget, isNull);
      expect(outcome.colonialPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.colonialMilitaryPlan, ColonialMilitaryPlan.defaultPlan);
      expect(outcome.colonialNavalPlan, ColonialNavalPlan.defaultPlan);
      expect(outcome.colonialCivilianWorkOrders, isEmpty);
      expect(outcome.developPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.developCivilianWorkOrders, isEmpty);
    });
  });
}
