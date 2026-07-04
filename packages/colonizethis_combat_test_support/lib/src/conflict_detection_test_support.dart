// Shared land conflict-detection test fixtures (Refs #3865).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Standard two-player setup for land conflict-detection tests.
const landConflictTestPlayers = [
  Player(id: 'player1', displayName: 'P1', isHuman: true),
  Player(id: 'player2', displayName: 'P2', isHuman: true),
];

/// Alternate player ids used in some unowned-province scenarios.
const landConflictShortPlayers = [
  Player(id: 'p1', displayName: 'P1', isHuman: true),
  Player(id: 'p2', displayName: 'P2', isHuman: true),
];

/// Two-player game with optional region data, armies, and orders wiring.
Game landConflictTwoPlayerGame({
  required String id,
  required List<Player> players,
  RegionData? oldWorld,
  RegionData? newWorld,
  List<Army> armies = const [],
}) =>
    TestFixtures.minimalGame(
      id: id,
      players: players,
      oldWorld: oldWorld,
      newWorld: newWorld,
      armies: armies,
    );

/// Move order targeting tile 0|0 in [provinceId].
MoveOrder landConflictMoveOrder({
  required String unitId,
  required String provinceId,
}) =>
    MoveOrder(unitId: unitId, destinationTileKey: '$provinceId|0|0');
