// Table-driven propagate-road-to-adjacent-capital scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/orders_application_completed_work.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'propagate_road_to_adjacent_capital_fixtures.dart';

void pracRunUnchangedWhenPlayerNull() {
  final ts = TileMapState();
  final ws = pracEmptyWorldState();
  final out = propagateRoadToAdjacentCapitalOrPort(
    tileKey: pracCapitalKey,
    nextLevel: 2,
    player: null,
    worldState: ws,
    tileMapByRegion: const {},
    tileState: ts,
  );
  expect(identical(out, ts), isTrue);
}

void pracRunUnchangedWhenTileKeyMalformed() {
  final ts = TileMapState();
  final ws = pracEmptyWorldState();
  final out = propagateRoadToAdjacentCapitalOrPort(
    tileKey: 'not-a-tile-key',
    nextLevel: 2,
    player: pracPlayerWithCapital(),
    worldState: ws,
    tileMapByRegion: const {},
    tileState: ts,
  );
  expect(identical(out, ts), isTrue);
}

void pracRunPropagatesToAdjacentCapitalWhenHigher() {
  final tileMap = pracPlain3x3TileMap();
  final tileState = TileMapState()
      .setRoadLevel(pracCapitalKey, 1)
      .setRoadLevel(pracBuildKey, 2);
  final ws = pracEmptyWorldState();

  final out = propagateRoadToAdjacentCapitalOrPort(
    tileKey: pracBuildKey,
    nextLevel: pracNextLevel,
    player: pracPlayerWithCapital(),
    worldState: ws,
    tileMapByRegion: {pracOw: tileMap},
    tileState: tileState,
  );

  expect(out.roadLevel(pracCapitalKey), pracNextLevel);
}

void pracRunPropagatesToAdjacentPortWhenHigher() {
  final tileMap = pracPlain3x3TileMap();
  final tileState = TileMapState()
      .setRoadLevel(pracCapitalKey, 1)
      .setRoadLevel(pracBuildKey, 2);
  final ws = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
    portsByProvinceSeaboard: {'$pracProvinceFull|sz1': pracCapitalKey},
  );

  final out = propagateRoadToAdjacentCapitalOrPort(
    tileKey: pracBuildKey,
    nextLevel: pracNextLevel,
    player: pracPlayerWithoutCapital,
    worldState: ws,
    tileMapByRegion: {pracOw: tileMap},
    tileState: tileState,
  );

  expect(out.roadLevel(pracCapitalKey), pracNextLevel);
}

/// Canonical scenarios for propagate_road_to_adjacent_capital family tests.
List<RunnableScenario> propagateRoadToAdjacentCapitalScenarios() => const [
  RunnableScenario(
    label: 'returns unchanged when player is null',
    run: pracRunUnchangedWhenPlayerNull,
  ),
  RunnableScenario(
    label: 'returns unchanged when tile key is malformed',
    run: pracRunUnchangedWhenTileKeyMalformed,
  ),
  RunnableScenario(
    label: 'propagates road level to adjacent capital tile when higher',
    run: pracRunPropagatesToAdjacentCapitalWhenHigher,
  ),
  RunnableScenario(
    label: 'propagates road level to adjacent port tile when higher',
    run: pracRunPropagatesToAdjacentPortWhenHigher,
  ),
];
