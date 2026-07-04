// Shared land-resolver integration fixtures (Refs #3865).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Standard att/def player pair for land resolver integration tests.
const landResolverAttDefPlayers = [
  Player(id: 'att', displayName: 'Att', isHuman: true),
  Player(id: 'def', displayName: 'Def', isHuman: false),
];

/// Both-human att/def pair.
const landResolverHumanPlayers = [
  Player(id: 'att', displayName: 'Att', isHuman: true),
  Player(id: 'def', displayName: 'Def', isHuman: true),
];

/// Napoleon/Frederick leader keys for multiplier path tests.
const landResolverNapoleonFrederickPlayers = [
  Player(
    id: 'att',
    displayName: 'France',
    isHuman: true,
    leaderKey: 'napoleon',
  ),
  Player(
    id: 'def',
    displayName: 'Prussia',
    isHuman: false,
    leaderKey: 'frederick',
  ),
];

/// Single-province Old World battle [Game] with optional generals/seed.
Game landResolverBattleGame({
  String id = 'g1',
  int turnNumber = 1,
  TurnPhase phase = TurnPhase.orders,
  String provinceId = 'p',
  String regionId = 'oldWorld',
  String defenderOwnerId = 'def',
  required List<Unit> units,
  List<Province>? provinces,
  RegionData? newWorld,
  List<Player>? players,
  List<General> generals = const [],
  int? globalGameSeed,
}) {
  final provinceList = provinces ??
      [
        Province(
          id: provinceId,
          regionId: regionId,
          ownerId: defenderOwnerId,
        ),
      ];
  return Game(
    id: id,
    globalGameSeed: globalGameSeed,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinceList, units: units),
      newWorld: newWorld ?? const RegionData(),
    ),
    players: players ?? landResolverAttDefPlayers,
    generals: generals,
  );
}

/// New World battle [Game] (empty Old World).
Game landResolverNewWorldBattleGame({
  String id = 'g1',
  int turnNumber = 1,
  required String provinceId,
  required List<Unit> units,
  List<Player>? players,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: 'newWorld', ownerId: 'def'),
        ],
        units: units,
      ),
    ),
    players: players ?? landResolverHumanPlayers,
  );
}

/// Empty-region [Game] with optional global seed (RNG factory tests).
Game landResolverSeededEmptyGame({
  String id = 'g',
  int? globalGameSeed,
  int turnNumber = 1,
  List<Player> players = const [],
}) {
  return Game(
    id: id,
    globalGameSeed: globalGameSeed,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}

/// Multi-province Old World game for general-assignment ledger tests.
Game landResolverMultiProvinceGame({
  String id = 'g1',
  int turnNumber = 4,
  required List<Province> provinces,
  List<General> generals = const [],
  List<Player> players = landResolverHumanPlayers,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(),
    ),
    players: players,
    generals: generals,
  );
}

/// Three-attacker tie-break fixture for [resolveBattleContext] determinism.
Game landResolverTieBreakGame() {
  return Game(
    id: 'g1',
    globalGameSeed: 1234,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
      oldWorld: RegionData(
        provinces: const [
          Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
        ],
        units: [
          Unit(
            id: 'a1',
            type: 'pikemen',
            ownerId: 'attA',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'a2',
            type: 'pikemen',
            ownerId: 'attB',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'p',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'attA', displayName: 'A', isHuman: true),
      Player(id: 'attB', displayName: 'B', isHuman: true),
      Player(id: 'def', displayName: 'D', isHuman: true),
    ],
  );
}

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

/// Mutual-annihilation garrison-recovery fixture with optional minors/tribes.
Game landResolverMutualAnnihilationGame({
  required String provinceId,
  required String defenderOwnerId,
  required List<Unit> units,
  required List<Player> players,
  int turnNumber = 1,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
}) {
  return Game(
    id: 'g1',
    minorNations: minorNations,
    tribes: tribes,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: 'oldWorld',
            ownerId: defenderOwnerId,
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
    ),
    players: players,
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
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
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
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
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

/// Standard single-province [BattleContext] for land resolver tests.
BattleContext landResolverBattleContext({
  String provinceId = 'p',
  String regionId = 'oldWorld',
  String defenderFactionId = 'def',
  required List<String> defenderUnitIds,
  required List<AttackingSide> attackers,
  int fortLevel = 0,
  String terrain = 'plains',
}) {
  return BattleContext(
    provinceId: provinceId,
    regionId: regionId,
    defenderFactionId: defenderFactionId,
    defenderUnitIds: defenderUnitIds,
    attackers: attackers,
    fortLevel: fortLevel,
    terrain: terrain,
  );
}
