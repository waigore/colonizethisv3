import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_shared_validator_test_helpers.dart';

/// Equivalence coverage for the optional `sharedCandidateValidator` parameter
/// on top-level suggest functions (Refs #2394,
/// SPEC/program/order-suggestions.md § Throughput bounds).
///
/// When a caller supplies an externally constructed
/// `IncrementalCandidateValidator` built with matching
/// `(game, view.playerId, currentOrders)` inputs, the returned suggestions are
/// identical to the default path that builds the validator internally. Also
/// verifies that pre-supplying `view` / `unitsById` to `forPlayer` does not
/// change observable suggestions.
///
/// Negative coverage (mismatched playerId assertions) lives in
/// `order_suggestion_shared_validator_negative_test.dart`.
void main() {
  suppressLogsForTests();

  group('shared validator equivalence (Refs #2394)', () {
    test('suggestMoveOrders matches default path', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      const orders = Orders();

      final defaultPath = suggestMoveOrders(view, game, topology, orders);
      final sharedValidator = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
      );
      final sharedPath = suggestMoveOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      );
      expect(sharedPath, equals(defaultPath));
    });

    test('suggestArmyMoveOrders matches default path', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      const orders = Orders();

      final defaultPath = suggestArmyMoveOrders(view, game, topology, orders);
      final sharedValidator = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
      );
      final sharedPath = suggestArmyMoveOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      );
      expect(sharedPath, equals(defaultPath));
    });

    test('suggestWorkOrders matches default path', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      const orders = Orders();

      final defaultPath = suggestWorkOrders(view, game, topology, orders);
      final sharedValidator = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
      );
      final sharedPath = suggestWorkOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      );
      expect(sharedPath, equals(defaultPath));
    });

    test('suggestBuildOrders matches default path', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      const orders = Orders();

      final defaultPath = suggestBuildOrders(view, game, topology, orders);
      final sharedValidator = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
      );
      final sharedPath = suggestBuildOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      );
      expect(sharedPath, equals(defaultPath));
    });

    test('suggestDiplomaticOrders is deterministic across repeated calls', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      const orders = Orders();

      final first = suggestDiplomaticOrders(view, game, topology, orders);
      final second = suggestDiplomaticOrders(view, game, topology, orders);
      expect(second, equals(first));
    });

    test(
      'shared validator built with externally provided view/unitsById produces '
      'identical suggestions to forPlayer default path (no internal rebuild)',
      () {
        final game = buildGame();
        final topology = buildTopology();
        final view = buildPlayerView(game, topology, gp);
        final unitsById = unitsByIdFromWorld(game.worldState);
        const orders = Orders();

        final defaultValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: gp,
          basePrefix: orders,
        );

        final sharedValidator = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: gp,
          basePrefix: orders,
          view: view,
          unitsById: unitsById,
        );

        expect(
          suggestMoveOrders(
            view,
            game,
            topology,
            orders,
            sharedCandidateValidator: defaultValidator,
          ),
          equals(
            suggestMoveOrders(
              view,
              game,
              topology,
              orders,
              sharedCandidateValidator: sharedValidator,
            ),
          ),
        );
        expect(
          suggestArmyMoveOrders(
            view,
            game,
            topology,
            orders,
            sharedCandidateValidator: defaultValidator,
          ),
          equals(
            suggestArmyMoveOrders(
              view,
              game,
              topology,
              orders,
              sharedCandidateValidator: sharedValidator,
            ),
          ),
        );
        expect(
          suggestWorkOrders(
            view,
            game,
            topology,
            orders,
            sharedCandidateValidator: defaultValidator,
          ),
          equals(
            suggestWorkOrders(
              view,
              game,
              topology,
              orders,
              sharedCandidateValidator: sharedValidator,
            ),
          ),
        );
        expect(
          suggestBuildOrders(
            view,
            game,
            topology,
            orders,
            sharedCandidateValidator: defaultValidator,
          ),
          equals(
            suggestBuildOrders(
              view,
              game,
              topology,
              orders,
              sharedCandidateValidator: sharedValidator,
            ),
          ),
        );
      },
    );

    test('forBasePrefix matches fresh forPlayer for same basePrefix', () {
      final game = buildGame();
      final topology = buildTopology();
      final view = buildPlayerView(game, topology, gp);
      final unitsById = unitsByIdFromWorld(game.worldState);
      const orders = Orders();

      final initial = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
        view: view,
        unitsById: unitsById,
      );
      final rebound = initial.forBasePrefix(orders);
      final fresh = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: gp,
        basePrefix: orders,
        view: view,
        unitsById: unitsById,
      );

      expect(
        suggestMoveOrders(
          view,
          game,
          topology,
          orders,
          sharedCandidateValidator: rebound,
        ),
        equals(
          suggestMoveOrders(
            view,
            game,
            topology,
            orders,
            sharedCandidateValidator: fresh,
          ),
        ),
      );
    });
  });
}
