import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/ai/simple_ai_heuristics.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_shared_validator_test_helpers.dart';

/// Negative coverage for the optional `sharedCandidateValidator` parameter
/// (Refs #2394, SPEC/program/order-suggestions.md § Throughput bounds): each
/// suggest family must trip an assertion when handed a validator built for a
/// different player, and `IncrementalCandidateValidator.forPlayer` must reject
/// a foreign pre-built `view`. Plus a smoke test that
/// `generateOrdersWithSimpleHeuristics` still produces legal army-move orders
/// under the shared-validator code path.
///
/// Equivalence coverage lives in
/// `order_suggestion_shared_validator_equivalence_test.dart`.
void main() {
  suppressLogsForTests();

  group('shared validator playerId mismatch is rejected', () {
    test(
      'suggestMoveOrders trips assertion when validator is for a different '
      'player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final wrongValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'gp2',
          basePrefix: const Orders(),
        );
        expect(
          () => suggestMoveOrders(
            view,
            game,
            topology,
            const Orders(),
            sharedCandidateValidator: wrongValidator,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'suggestArmyMoveOrders trips assertion when validator is for a '
      'different player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final wrongValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'gp2',
          basePrefix: const Orders(),
        );
        expect(
          () => suggestArmyMoveOrders(
            view,
            game,
            topology,
            const Orders(),
            sharedCandidateValidator: wrongValidator,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'suggestWorkOrders trips assertion when validator is for a different '
      'player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final wrongValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'gp2',
          basePrefix: const Orders(),
        );
        expect(
          () => suggestWorkOrders(
            view,
            game,
            topology,
            const Orders(),
            sharedCandidateValidator: wrongValidator,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'suggestBuildOrders trips assertion when validator is for a different '
      'player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final wrongValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'gp2',
          basePrefix: const Orders(),
        );
        expect(
          () => suggestBuildOrders(
            view,
            game,
            topology,
            const Orders(),
            sharedCandidateValidator: wrongValidator,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'IncrementalCandidateValidator.forPlayer trips assertion when supplied '
      'view is for a different player',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final foreignView = buildPlayerView(game, topology, 'gp2');
        expect(
          () => IncrementalCandidateValidator.forPlayer(
            game: game,
            topology: topology,
            playerId: gp,
            basePrefix: const Orders(),
            resolution: orderResolutionContextFromView(foreignView, game),
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });

  group('generateOrdersWithSimpleHeuristics still produces the same orders', () {
    test(
      'orders generated under the new shared-validator code path are unchanged '
      'against a known fixture',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final orders = generateOrdersWithSimpleHeuristics(
          game,
          topology,
          gp,
          turnSeedForPlayer(game, gp, 1, fallbackAiSeed: 42),
        );
        expect(orders.workOrdersByPlayerId, isNotNull);
        final armyMoves = orders.armyMoveOrdersByPlayerId[gp] ?? const [];
        for (final m in armyMoves) {
          expect(
            m.destinationProvinceId,
            anyOf(cap, p1, p2),
            reason:
                'army move destination must be one of the corpus provinces',
          );
        }
      },
    );
  });
}
