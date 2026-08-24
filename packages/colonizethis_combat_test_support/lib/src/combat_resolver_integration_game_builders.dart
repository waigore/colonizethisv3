// Phase/index/spy integration [Game] builders (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'combat_resolver_player_constants.dart';

/// Pre-combat index tests: armies + optional Old World body.
Game preCombatIndexGame({
  List<Player> players = const [
    Player(id: 'p1', displayName: 'P1', isHuman: true),
    Player(id: 'p2', displayName: 'P2', isHuman: false),
  ],
  List<Army> armies = const [],
  RegionData? oldWorld,
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: oldWorld ?? const RegionData(),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: players,
  );
}

/// bindGeneralsForCombatPhase multi-battle fixture.
Game bindGeneralsPhaseGame({
  List<General> generals = const [
    General(id: 'gatt1', ownerId: 'att', medals: 9),
    General(id: 'gatt2', ownerId: 'att', medals: 2),
    General(id: 'gdef1', ownerId: 'def', medals: 3),
  ],
}) {
  return Game(
    id: 'g1',
    globalGameSeed: 7,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: RegionData(
        provinces: const [
          Province(id: 'p1', regionId: 'oldWorld', ownerId: 'def'),
          Province(id: 'p2', regionId: 'oldWorld', ownerId: 'def'),
          Province(id: 'p3', regionId: 'oldWorld', ownerId: 'def'),
        ],
        units: const [],
      ),
      newWorld: const RegionData(),
    ),
    players: landResolverHumanPlayers,
    generals: generals,
  );
}

/// Thin wrapper over [TestFixtures.minimalGame] for complex integration tests.
Game combatResolverMinimalGame({
  String id = 'g',
  List<Player> players = landResolverHumanPlayers,
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 1,
  RegionData? oldWorld,
  RegionData? newWorld,
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, String>? purchasedTilesByTileKey,
  Map<String, Map<String, int>> spyRevealTurnsByPlayer = const {},
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
}) {
  return TestFixtures.minimalGame(
    id: id,
    players: players,
    phase: phase,
    turnNumber: turnNumber,
    oldWorld: oldWorld,
    newWorld: newWorld,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    playerVisibilityByTile: playerVisibilityByTile,
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    spyRevealTurnsByPlayer: spyRevealTurnsByPlayer,
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Spy-timer / visibility fixture for combat conquest tests.
Game combatSpyTimerGame({
  String id = 'g1',
  required String provinceId,
  required String regionId,
  required String defenderOwnerId,
  required List<Unit> units,
  RegionData? newWorld,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Map<String, int>> spyRevealTurnsByPlayer = const {},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
  Map<String, String>? purchasedTilesByTileKey,
  List<Player> players = landResolverHumanPlayers,
}) {
  return combatResolverMinimalGame(
    id: id,
    players: players,
    oldWorld: RegionData(
      provinces: [
        Province(id: provinceId, regionId: regionId, ownerId: defenderOwnerId),
      ],
      units: units,
    ),
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
    spyRevealTurnsByPlayer: spyRevealTurnsByPlayer,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    purchasedTilesByTileKey: purchasedTilesByTileKey,
  );
}
