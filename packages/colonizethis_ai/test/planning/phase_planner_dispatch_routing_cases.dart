// Case bodies for `phase_planner_dispatch_test.dart` (Refs #4310 Slice D).
// Phase routing matrix for `runPhasePlanners`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';

void registerPhasePlannerDispatchRoutingCases() {
  group('runPhasePlanners phase routing', () {
    test('EXPAND when OW below quota', () {
      final outcome = runPhasePlanners(
        game: buildPhasePlannerDispatchExpandGame(),
        snapshot: buildPhasePlannerDispatchExpandSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.expand);
    });

    test('COLONIAL-lite when turn>=120, OW=9, NW non-GP-owned visible', () {
      final outcome = runPhasePlanners(
        game: buildPhasePlannerDispatchColonialLiteGame(),
        snapshot: buildPhasePlannerDispatchColonialLiteSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.colonialLite);
    });

    test('COLONIAL when OW at quota with colonial acquisition targets', () {
      final outcome = runPhasePlanners(
        game: buildPhasePlannerDispatchColonialGame(),
        snapshot: buildPhasePlannerDispatchColonialSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.colonial);
    });

    test('DEVELOP when OW at quota and no colonial acquisition targets', () {
      final outcome = runPhasePlanners(
        game: buildPhasePlannerDispatchDevelopGame(),
        snapshot: buildPhasePlannerDispatchDevelopSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.develop);
    });
  });
}
