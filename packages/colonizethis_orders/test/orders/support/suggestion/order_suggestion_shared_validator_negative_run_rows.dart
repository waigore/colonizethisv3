// Scenario run tear-offs for order_suggestion_shared_validator_negative (Refs #3949 wave 3).

import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'order_suggestion_shared_validator_test_helpers.dart';

void ossvnRunSuggestMoveOrdersWrongPlayer() {
  _expectWrongPlayerTripsAssertion(suggestMoveOrders);
}

void ossvnRunSuggestArmyMoveOrdersWrongPlayer() {
  _expectWrongPlayerTripsAssertion(suggestArmyMoveOrders);
}

void ossvnRunSuggestWorkOrdersWrongPlayer() {
  _expectWrongPlayerTripsAssertion(suggestWorkOrders);
}

void ossvnRunSuggestBuildOrdersWrongPlayer() {
  _expectWrongPlayerTripsAssertion(suggestBuildOrders);
}

void ossvnRunForPlayerForeignView() {
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
}

void ossvnRunSimpleHeuristicsSmokeFixture() {
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
      reason: 'army move destination must be one of the corpus provinces',
    );
  }
}

void _expectWrongPlayerTripsAssertion<T>(
  void Function(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders orders, {
    IncrementalCandidateValidator? sharedCandidateValidator,
  })
  suggest,
) {
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
    () => suggest(
      view,
      game,
      topology,
      const Orders(),
      sharedCandidateValidator: wrongValidator,
    ),
    throwsA(isA<AssertionError>()),
  );
}
