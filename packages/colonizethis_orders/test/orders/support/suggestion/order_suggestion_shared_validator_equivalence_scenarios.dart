// Table-driven shared-validator equivalence scenarios (Refs #3949 wave 3 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_shared_validator_test_helpers.dart';
// dart format off

typedef _SuggestFn<T> = List<T> Function(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders orders, {
  IncrementalCandidateValidator? sharedCandidateValidator,
});

void ossveRunSuggestMoveOrdersMatchesDefaultPath() {_expectSuggestFamilyMatchesDefault(suggestMoveOrders);}

void ossveRunSuggestArmyMoveOrdersMatchesDefaultPath() {_expectSuggestFamilyMatchesDefault(suggestArmyMoveOrders);}

void ossveRunSuggestWorkOrdersMatchesDefaultPath() {_expectSuggestFamilyMatchesDefault(suggestWorkOrders);}

void ossveRunSuggestBuildOrdersMatchesDefaultPath() {_expectSuggestFamilyMatchesDefault(suggestBuildOrders);}

void ossveRunSuggestDiplomaticOrdersDeterministicAcrossRepeatedCalls() {final game = buildGame(); final topology = buildTopology(); final view = buildPlayerView(game,topology,gp); const orders = Orders(); final first = suggestDiplomaticOrders(view,game,topology,orders); final second = suggestDiplomaticOrders(view,game,topology,orders); expect(second,equals(first));}

void ossveRunSharedValidatorExternalViewUnitsByIdMatchesForPlayerDefault() {_expectExternalViewUnitsByIdMatchesForPlayerDefault();}

void ossveRunForBasePrefixMatchesFreshForPlayer() {_expectForBasePrefixMatchesFreshForPlayer();}

void _expectSuggestEq<T>(
  _SuggestFn<T> suggest,
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders orders,
  IncrementalCandidateValidator a,
  IncrementalCandidateValidator b,
) {
  expect(
    suggest(view, game, topology, orders, sharedCandidateValidator: a),
    equals(suggest(view, game, topology, orders, sharedCandidateValidator: b)),
  );
}

void _expectSuggestFamilyMatchesDefault<T>(_SuggestFn<T> suggest) {
  final game = buildGame();
  final topology = buildTopology();
  final view = buildPlayerView(game, topology, gp);
  const orders = Orders();
  final sharedValidator = IncrementalCandidateValidator.forPlayer(
    game: game, topology: topology, playerId: gp, basePrefix: orders,
  );
  expect(
    suggest(view, game, topology, orders, sharedCandidateValidator: sharedValidator),
    equals(suggest(view, game, topology, orders)),
  );
}

void _expectExternalViewUnitsByIdMatchesForPlayerDefault() {
  final game = buildGame();
  final topology = buildTopology();
  final view = buildPlayerView(game, topology, gp);
  final unitsById = unitsByIdFromWorld(game.worldState);
  const orders = Orders();
  final defaultValidator = IncrementalCandidateValidator.forPlayer(
    game: game, topology: topology, playerId: gp, basePrefix: orders,
  );
  final sharedValidator = IncrementalCandidateValidator.forPlayer(
    game: game, topology: topology, playerId: gp, basePrefix: orders,
    resolution: orderResolutionContextFromView(view, game, unitsById: unitsById),
  );
  _expectSuggestEq(suggestMoveOrders, view, game, topology, orders, defaultValidator, sharedValidator);
  _expectSuggestEq(suggestArmyMoveOrders, view, game, topology, orders, defaultValidator, sharedValidator);
  _expectSuggestEq(suggestWorkOrders, view, game, topology, orders, defaultValidator, sharedValidator);
  _expectSuggestEq(suggestBuildOrders, view, game, topology, orders, defaultValidator, sharedValidator);
  _expectSuggestEq(suggestNavalMoveOrders, view, game, topology, orders, defaultValidator, sharedValidator);
  _expectSuggestEq(suggestNavalMissionOrders, view, game, topology, orders, defaultValidator, sharedValidator);
  _expectSuggestEq(suggestDiplomaticOrders, view, game, topology, orders, defaultValidator, sharedValidator);
}

void _expectForBasePrefixMatchesFreshForPlayer() {
  final game = buildGame();
  final topology = buildTopology();
  final view = buildPlayerView(game, topology, gp);
  final unitsById = unitsByIdFromWorld(game.worldState);
  const orders = Orders();
  final resolution = orderResolutionContextFromView(view, game, unitsById: unitsById);
  final rebound = IncrementalCandidateValidator.forPlayer(
    game: game, topology: topology, playerId: gp, basePrefix: orders, resolution: resolution,
  ).forBasePrefix(orders);
  final fresh = IncrementalCandidateValidator.forPlayer(
    game: game, topology: topology, playerId: gp, basePrefix: orders, resolution: resolution,
  );
  _expectSuggestEq(suggestMoveOrders, view, game, topology, orders, rebound, fresh);
}

List<RunnableScenario>
orderSuggestionSharedValidatorEquivalenceScenarios() => [
  rs('suggestMoveOrders matches default path', ossveRunSuggestMoveOrdersMatchesDefaultPath),
  rs('suggestArmyMoveOrders matches default path', ossveRunSuggestArmyMoveOrdersMatchesDefaultPath),
  rs('suggestWorkOrders matches default path', ossveRunSuggestWorkOrdersMatchesDefaultPath),
  rs('suggestBuildOrders matches default path', ossveRunSuggestBuildOrdersMatchesDefaultPath),
  rs('suggestDiplomaticOrders is deterministic across repeated calls', ossveRunSuggestDiplomaticOrdersDeterministicAcrossRepeatedCalls),
  rs('shared validator built with externally provided view/unitsById produces identical suggestions to forPlayer default path (no internal rebuild)', ossveRunSharedValidatorExternalViewUnitsByIdMatchesForPlayerDefault, '#2394'),
  rs('forBasePrefix matches fresh forPlayer for same basePrefix', ossveRunForBasePrefixMatchesFreshForPlayer),
];
