// Fixtures for order-resolution context scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const orcPlayerId = 'p1';

Game orcMinimalGame() => TestFixtures.minimalGame(
  players: const [Player(id: orcPlayerId, displayName: 'P1', isHuman: true)],
);

MapTopology orcEmptyTopology() => const MapTopology(nodes: [], edges: []);

PlayerView orcPlayerView(Game game) =>
    buildPlayerView(game, orcEmptyTopology(), orcPlayerId);
