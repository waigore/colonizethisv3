// Table-driven shared-validator equivalence scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_shared_validator_test_helpers.dart';
// dart format off

void ossveRunSuggestMoveOrdersMatchesDefaultPath() {_expectSuggestFamilyMatchesDefault(suggestMoveOrders);}

void ossveRunSuggestArmyMoveOrdersMatchesDefaultPath() {_expectSuggestFamilyMatchesDefault(suggestArmyMoveOrders);}

void ossveRunSuggestWorkOrdersMatchesDefaultPath() {_expectSuggestFamilyMatchesDefault(suggestWorkOrders);}

void ossveRunSuggestBuildOrdersMatchesDefaultPath() {_expectSuggestFamilyMatchesDefault(suggestBuildOrders);}

void ossveRunSuggestDiplomaticOrdersDeterministicAcrossRepeatedCalls() {final game = buildGame(); final topology = buildTopology(); final view = buildPlayerView(game,topology,gp); const orders = Orders(); final first = suggestDiplomaticOrders(view,game,topology,orders); final second = suggestDiplomaticOrders(view,game,topology,orders); expect(second,equals(first));}

void ossveRunSharedValidatorExternalViewUnitsByIdMatchesForPlayerDefault() {_expectExternalViewUnitsByIdMatchesForPlayerDefault();}

void ossveRunForBasePrefixMatchesFreshForPlayer() {_expectForBasePrefixMatchesFreshForPlayer();}

void _expectSuggestFamilyMatchesDefault<T>(
  List<T> Function(
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
  const orders = Orders();

  final defaultPath = suggest(view, game, topology, orders);
  final sharedValidator = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: gp,
    basePrefix: orders,
  );
  final sharedPath = suggest(
    view,
    game,
    topology,
    orders,
    sharedCandidateValidator: sharedValidator,
  );
  expect(sharedPath, equals(defaultPath));
}

void _expectExternalViewUnitsByIdMatchesForPlayerDefault() {
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
    resolution: orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    ),
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
  expect(
    suggestNavalMoveOrders(
      view,
      game,
      topology,
      orders,
      sharedCandidateValidator: defaultValidator,
    ),
    equals(
      suggestNavalMoveOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      ),
    ),
  );
  expect(
    suggestNavalMissionOrders(
      view,
      game,
      topology,
      orders,
      sharedCandidateValidator: defaultValidator,
    ),
    equals(
      suggestNavalMissionOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      ),
    ),
  );
  expect(
    suggestDiplomaticOrders(
      view,
      game,
      topology,
      orders,
      sharedCandidateValidator: defaultValidator,
    ),
    equals(
      suggestDiplomaticOrders(
        view,
        game,
        topology,
        orders,
        sharedCandidateValidator: sharedValidator,
      ),
    ),
  );
}

void _expectForBasePrefixMatchesFreshForPlayer() {
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
    resolution: orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    ),
  );
  final rebound = initial.forBasePrefix(orders);
  final fresh = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: gp,
    basePrefix: orders,
    resolution: orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    ),
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
