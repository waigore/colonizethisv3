import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Minimal [Game] with [armies] (and optional region unit lists) for army
/// command / migration pins (Refs #3978).
Game gameWithArmies({
  String id = 'g_army',
  List<Army> armies = const [],
  int nextArmySeq = 1,
  List<Player> players = const [
    Player(id: 'p1', displayName: 'P1', isHuman: true),
  ],
  List<Unit> oldWorldUnits = const [],
  List<Unit> newWorldUnits = const [],
  RegionData? oldWorld,
  RegionData? newWorld,
}) => TestFixtures.minimalGame(
  id: id,
  players: players,
  armies: armies,
  nextArmySeq: nextArmySeq,
  oldWorld:
      oldWorld ??
      (oldWorldUnits.isEmpty ? null : RegionData(units: oldWorldUnits)),
  newWorld:
      newWorld ??
      (newWorldUnits.isEmpty ? null : RegionData(units: newWorldUnits)),
);

/// Minimal [Game] with [fleets] for naval fleet-command pins (Refs #3978).
Game gameWithFleets({
  String id = 'g_naval',
  List<Fleet> fleets = const [],
  List<Player> players = const [
    Player(id: 'gp_human', displayName: 'Human', isHuman: true),
  ],
}) => TestFixtures.minimalGame(id: id, players: players, fleets: fleets);
