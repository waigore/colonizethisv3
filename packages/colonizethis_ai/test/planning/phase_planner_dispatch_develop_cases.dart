// Case bodies for `phase_planner_dispatch_test.dart` (Refs #4310 Slice D).
// DEVELOP outcome composition, determinism, and priority weights.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';
import 'ai_planner_fixtures.dart';

void registerPhasePlannerDispatchDevelopCases() {
  group('DEVELOP outcome composition', () {
    test('DEVELOP populates DEVELOP slots only', () {
      final game = buildPhasePlannerDispatchDevelopGame();
      final snapshot = buildPhasePlannerDispatchDevelopSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      expect(outcome.phase, ObserverGoalPhase.develop);
      expect(
        outcome.developPeaceTargetFactionIdsSorted,
        planDevelopPeace(game: game, snapshot: snapshot),
      );
      expect(
        outcome.developCivilianWorkOrders,
        planDevelopCivilian(game: game, snapshot: snapshot),
      );

      // EXPAND / COLONIAL slots stay default.
      expect(outcome.expandDeclareWarTargetFactionId, isNull);
      expect(outcome.expandPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
      expect(outcome.expandMilitaryPlan, ExpandMilitaryPlan.defaultPlan);
      expect(outcome.colonialLiteOverturesSorted, isEmpty);
      expect(outcome.colonialLiteNavalPlan, ColonialLiteNavalPlan.defaultPlan);
      expect(outcome.colonialAcquisitionTarget, isNull);
      expect(outcome.colonialPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.colonialMilitaryPlan, ColonialMilitaryPlan.defaultPlan);
      expect(outcome.colonialNavalPlan, ColonialNavalPlan.defaultPlan);
      expect(outcome.colonialCivilianWorkOrders, isEmpty);
    });
  });
}

void registerPhasePlannerDispatchDeterminismCases() {
  group('determinism (Must-have #7)', () {
    test('EXPAND outcome equal across repeated calls', () {
      final game = buildPhasePlannerDispatchExpandGame();
      final snapshot = buildPhasePlannerDispatchExpandSnapshot();
      final a = runPhasePlanners(game: game, snapshot: snapshot);
      final b = runPhasePlanners(game: game, snapshot: snapshot);
      expect(b.phase, a.phase);
      expect(
        b.expandDeclareWarTargetFactionId,
        a.expandDeclareWarTargetFactionId,
      );
      expect(
        b.expandPeaceTargetFactionIdsSorted,
        a.expandPeaceTargetFactionIdsSorted,
      );
      expect(b.expandEconomyPlan, a.expandEconomyPlan);
      expect(b.expandMilitaryPlan, a.expandMilitaryPlan);
    });

    test('COLONIAL outcome equal across repeated calls', () {
      final game = buildPhasePlannerDispatchColonialGame();
      final snapshot = buildPhasePlannerDispatchColonialSnapshot();
      final a = runPhasePlanners(game: game, snapshot: snapshot);
      final b = runPhasePlanners(game: game, snapshot: snapshot);
      expect(b.phase, a.phase);
      expect(b.colonialAcquisitionTarget, a.colonialAcquisitionTarget);
      expect(
        b.colonialPeaceTargetFactionIdsSorted,
        a.colonialPeaceTargetFactionIdsSorted,
      );
      expect(b.colonialMilitaryPlan, a.colonialMilitaryPlan);
      expect(b.colonialNavalPlan, a.colonialNavalPlan);
      expect(b.colonialCivilianWorkOrders, a.colonialCivilianWorkOrders);
    });
  });
}

void registerPhasePlannerDispatchPriorityWeightsCases() {
  group('priorityWeights field (Refs #2847 Phase 1 scaffolding)', () {
    test(
      'EXPAND outcome carries weights field-equal to computePhasePriorityWeights',
      () {
        final game = buildPhasePlannerDispatchExpandGame();
        final snapshot = buildPhasePlannerDispatchExpandSnapshot();
        final outcome = runPhasePlanners(game: game, snapshot: snapshot);
        expect(
          outcome.priorityWeights,
          computePhasePriorityWeights(
            snapshot: snapshot,
            game: game,
            expandEconomyPlan: outcome.expandEconomyPlan,
          ),
        );
      },
    );

    test('COLONIAL-lite outcome carries weights field-equal to '
        'computePhasePriorityWeights', () {
      final game = buildPhasePlannerDispatchColonialLiteGame();
      final snapshot = buildPhasePlannerDispatchColonialLiteSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);
      expect(
        outcome.priorityWeights,
        computePhasePriorityWeights(
          snapshot: snapshot,
          game: game,
          expandEconomyPlan: outcome.expandEconomyPlan,
        ),
      );
    });

    test('COLONIAL outcome carries weights from default ExpandEconomyPlan (no '
        'EXPAND planner ran)', () {
      final game = buildPhasePlannerDispatchColonialGame();
      final snapshot = buildPhasePlannerDispatchColonialSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);
      // Sanity: COLONIAL outcome leaves EXPAND plan at default.
      expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
      expect(
        outcome.priorityWeights,
        computePhasePriorityWeights(
          snapshot: snapshot,
          game: game,
          expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
        ),
      );
    });

    test('DEVELOP outcome carries weights from default ExpandEconomyPlan (no '
        'EXPAND planner ran)', () {
      final game = buildPhasePlannerDispatchDevelopGame();
      final snapshot = buildPhasePlannerDispatchDevelopSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);
      expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
      expect(
        outcome.priorityWeights,
        computePhasePriorityWeights(
          snapshot: snapshot,
          game: game,
          expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
        ),
      );
    });

    test(
      'weights are advisory — repeated dispatches yield identical weights',
      () {
        final game = buildPhasePlannerDispatchExpandGame();
        final snapshot = buildPhasePlannerDispatchExpandSnapshot();
        final a = runPhasePlanners(game: game, snapshot: snapshot);
        final b = runPhasePlanners(game: game, snapshot: snapshot);
        expect(b.priorityWeights, a.priorityWeights);
      },
    );
  });
}
