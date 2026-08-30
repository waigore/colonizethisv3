// Determinism guards for observer-phase NW-suppression predicates (Refs #3749;
// extracted from the matrix host Refs #4669).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/observer_goal_phase_nw_suppression_predicate_matrix_test_support.dart';

void registerObserverGoalPhaseNwSuppressionPredicateGameMatrixDeterminismCases() {
  group('shouldSuppressNewWorldColonialOrders determinism', () {
    test('identical phase inputs produce identical predicate outcome', () {
      final colonialLiteGame =
          observerGoalPhaseNwSuppressionMatrixGameWithTribeNw(
            turnNumber: kObserverColonialLiteMinTurn,
          );
      final colonialGame = observerGoalPhaseNwSuppressionMatrixGameWithTribeNw(
        turnNumber: 110,
      );
      final developGame = observerGoalPhaseNwSuppressionMatrixGameWithGpOwnedNw();
      final expandGame = observerGoalPhaseNwSuppressionMatrixGameWithTribeNw(
        turnNumber: 50,
      );

      for (final entry in <(AIWorldSnapshot, Game, bool)>[
        (kObserverGoalPhaseNwSuppressionMatrixExpandSnapshot, expandGame, true),
        (
          kObserverGoalPhaseNwSuppressionMatrixColonialLiteSnapshot,
          colonialLiteGame,
          false,
        ),
        (
          kObserverGoalPhaseNwSuppressionMatrixColonialSnapshot,
          colonialGame,
          false,
        ),
        (
          kObserverGoalPhaseNwSuppressionMatrixDevelopSnapshot,
          developGame,
          false,
        ),
      ]) {
        final (snapshot, game, expected) = entry;
        final first = shouldSuppressNewWorldColonialOrders(
          snapshot: snapshot,
          game: game,
        );
        final second = shouldSuppressNewWorldColonialOrders(
          snapshot: snapshot,
          game: game,
        );
        expect(first, expected);
        expect(second, first);
      }
    });
  });

  group('shouldSuppressNewWorldDeclareWarInvasionAndPurchase determinism', () {
    test('identical phase inputs produce identical predicate outcome', () {
      final colonialLiteGame =
          observerGoalPhaseNwSuppressionMatrixGameWithTribeNw(
            turnNumber: kObserverColonialLiteMinTurn,
          );
      final colonialGame = observerGoalPhaseNwSuppressionMatrixGameWithTribeNw(
        turnNumber: 110,
      );
      final developGame = observerGoalPhaseNwSuppressionMatrixGameWithGpOwnedNw();
      final expandGame = observerGoalPhaseNwSuppressionMatrixGameWithTribeNw(
        turnNumber: 50,
      );

      for (final entry in <(AIWorldSnapshot, Game, bool)>[
        (kObserverGoalPhaseNwSuppressionMatrixExpandSnapshot, expandGame, true),
        (
          kObserverGoalPhaseNwSuppressionMatrixColonialLiteSnapshot,
          colonialLiteGame,
          true,
        ),
        (
          kObserverGoalPhaseNwSuppressionMatrixColonialSnapshot,
          colonialGame,
          false,
        ),
        (
          kObserverGoalPhaseNwSuppressionMatrixDevelopSnapshot,
          developGame,
          true,
        ),
      ]) {
        final (snapshot, game, expected) = entry;
        final first = shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
          snapshot: snapshot,
          game: game,
        );
        final second = shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
          snapshot: snapshot,
          game: game,
        );
        expect(first, expected);
        expect(second, first);
      }
    });
  });
}
