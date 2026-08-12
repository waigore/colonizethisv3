// Case bodies for `phase_planner_dispatch_test.dart` (Refs #4310 Slice D).
// COLONIAL outcome composition.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';
import 'ai_planner_fixtures.dart';

const String _tribe1 = kColonialPhaseTribe1;

void registerPhasePlannerDispatchColonialCases() {
  group('COLONIAL outcome composition', () {
    test(
      'declareWar acquisition pairs target factionId into military / naval',
      () {
        // The fixture has an at-war tribe owning the NW invadable
        // province. `planColonialAcquisition` resolves to
        // `(tribe1, declareWar)` and the dispatcher forwards that
        // factionId into both `planColonialMilitary` and
        // `planColonialNaval` -- the at-war fallback arm fires for both
        // sibling plans with `_tribe1` listed as the priority owner.
        final game = buildPhasePlannerDispatchColonialGame();
        final snapshot = buildPhasePlannerDispatchColonialSnapshot();
        final outcome = runPhasePlanners(game: game, snapshot: snapshot);

        expect(outcome.phase, ObserverGoalPhase.colonial);

        // Acquisition arm: declareWar over the tribe (Join Empire and
        // purchase_land arms have no overture / merchant).
        expect(
          outcome.colonialAcquisitionTarget,
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.declareWar,
          ),
        );

        // Military / naval invasion-transport restricted to the
        // declared target.
        expect(
          outcome.colonialMilitaryPlan,
          planColonialMilitary(
            game: game,
            snapshot: snapshot,
            colonialDeclaredWarTargetFactionId: _tribe1,
          ),
        );
        expect(
          outcome.colonialNavalPlan,
          planColonialNaval(
            game: game,
            snapshot: snapshot,
            colonialDeclaredWarTargetFactionId: _tribe1,
          ),
        );

        // Peace + civilian still flow.
        expect(
          outcome.colonialPeaceTargetFactionIdsSorted,
          planColonialPeace(game: game, snapshot: snapshot),
        );
        expect(
          outcome.colonialCivilianWorkOrders,
          planColonialCivilian(game: game, snapshot: snapshot),
        );

        // EXPAND / COLONIAL-lite / DEVELOP slots stay default.
        expect(outcome.expandDeclareWarTargetFactionId, isNull);
        expect(outcome.expandPeaceTargetFactionIdsSorted, isEmpty);
        expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
        expect(outcome.expandMilitaryPlan, ExpandMilitaryPlan.defaultPlan);
        expect(outcome.colonialLiteOverturesSorted, isEmpty);
        expect(
          outcome.colonialLiteNavalPlan,
          ColonialLiteNavalPlan.defaultPlan,
        );
        expect(outcome.developPeaceTargetFactionIdsSorted, isEmpty);
        expect(outcome.developCivilianWorkOrders, isEmpty);
      },
    );

    test('null acquisition leaves military / naval to at-war fallback arm', () {
      // Zero regiments + no Join Empire / purchase_land path means
      // `planColonialAcquisition` returns null; the dispatcher must
      // therefore pass `null` as `colonialDeclaredWarTargetFactionId`
      // and the at-war fallback arms fire identically to a direct
      // call.
      final game = buildPhasePlannerDispatchColonialGame(regimentCount: 0);
      // Still at-war with the tribe so the at-war fallback arm
      // populates the priority owner roster (tribe1) for both
      // military and naval.
      final snapshot = buildPhasePlannerDispatchColonialSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      expect(outcome.phase, ObserverGoalPhase.colonial);
      expect(
        outcome.colonialAcquisitionTarget,
        isNull,
        reason:
            'Zero regiments + no overture / merchant => null '
            'acquisition target.',
      );
      expect(
        outcome.colonialMilitaryPlan,
        planColonialMilitary(game: game, snapshot: snapshot),
        reason:
            'Dispatcher forwards null colonialDeclaredWarTargetFactionId '
            'so the planner picks via the at-war fallback arm.',
      );
      expect(
        outcome.colonialNavalPlan,
        planColonialNaval(game: game, snapshot: snapshot),
        reason:
            'Naval pairs with military on the same '
            'colonialDeclaredWarTargetFactionId argument.',
      );
    });
  });
}
