import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared [Game] / [WorldState] factories for cross-package tests.
///
/// Refs waigore/colonizethis#2071 (centralize repeated setup); #3424 Slice 1.
abstract final class TestFixtures {
  TestFixtures._();

  /// Both regions empty; tunable turn.
  static WorldState emptyWorldState({
    TurnPhase phase = TurnPhase.orders,
    int turnNumber = 1,
  }) => WorldState(
    turnState: TurnState(phase: phase, turnNumber: turnNumber),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  );

  /// [TurnPhase.orders] with optional region bodies (defaults empty).
  static WorldState worldStateAtOrdersPhase({
    int turnNumber = 1,
    RegionData? oldWorld,
    RegionData? newWorld,
    TileMapState? tileState,
  }) {
    return WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: oldWorld ?? const RegionData(),
      newWorld: newWorld ?? const RegionData(),
      tileState: tileState ?? const TileMapState(),
    );
  }

  /// Minimal [Game] with default empty regions and a single human player.
  static Game minimalGame({
    String id = 'g',
    List<Player> players = const [
      Player(id: 'h1', displayName: 'Human', isHuman: true),
    ],
    TurnPhase phase = TurnPhase.orders,
    int turnNumber = 1,
    RegionData? oldWorld,
    RegionData? newWorld,
    Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
        const {},
    Map<String, Map<String, String>>? playerVisibilityByTile,
    Map<String, String>? resourceByTileKey,
    Map<String, String>? purchasedTilesByTileKey,
    Map<String, String>? portsByProvinceSeaboard,
    Map<String, Set<String>>? playerProspectedTiles,
    TileMapState? tileState,
    List<Army> armies = const [],
    List<Fleet> fleets = const [],
    double richesCashMultiplier = 1.0,
    int capitalTileGrainBonusPerTurn = 5,
    List<MinorNation> minorNations = const [],
    List<Tribe> tribes = const [],
    List<OvertureState> overtureStates = const [],
    List<DiplomacyRelation> diplomacyRelations = const [],
  }) => Game(
    id: id,
    capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: oldWorld ?? const RegionData(),
      newWorld: newWorld ?? const RegionData(),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      playerVisibilityByTile: playerVisibilityByTile ?? const {},
      resourceByTileKey: resourceByTileKey ?? const {},
      purchasedTilesByTileKey: purchasedTilesByTileKey ?? const {},
      portsByProvinceSeaboard: portsByProvinceSeaboard ?? const {},
      playerProspectedTiles: playerProspectedTiles ?? const {},
      tileState: tileState ?? const TileMapState(),
      armies: armies,
      fleets: fleets,
    ),
    players: players,
    richesCashMultiplier: richesCashMultiplier,
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtureStates,
    diplomacyRelations: diplomacyRelations,
  );

  /// Old World land with [unit]; New World empty. Default provinces match
  /// common work-order tests (`oldWorld|p1`, `oldWorld|p2`).
  static Game oldWorldGameWithUnit({
    required Unit unit,
    List<Province> provinces = const [
      Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
    ],
    List<Player> players = const [
      Player(id: 'h1', displayName: 'Human', isHuman: true),
    ],
    int turnNumber = 1,
    Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
        const {},
    TileMapState? tileState,
  }) => minimalGame(
    players: players,
    turnNumber: turnNumber,
    oldWorld: RegionData(provinces: provinces, units: [unit]),
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    tileState: tileState,
  );

  /// One old-world province owned by the sole player (validator / spawn tests).
  static Game gameWithSingleOwnedProvince({
    String id = 'g',
    String ownerPlayerId = 'gp1',
    String provinceId = 'oldWorld|p1',
    int treasury = 0,
    String displayName = 'P',
    bool isHuman = true,
  }) => minimalGame(
    id: id,
    players: [
      Player(
        id: ownerPlayerId,
        displayName: displayName,
        isHuman: isHuman,
        capitalProvinceId: provinceId,
        treasury: treasury,
      ),
    ],
    oldWorld: RegionData(
      provinces: [
        Province(id: provinceId, regionId: 'oldWorld', ownerId: ownerPlayerId),
      ],
    ),
  );

  static const String _defaultSinglePlayerGameId = 't';

  /// Minimal [Game] with one [player] and empty both regions.
  static Game singlePlayerGame(
    Player player, {
    String gameId = _defaultSinglePlayerGameId,
    WorldState? worldState,
  }) {
    return Game(
      id: gameId,
      worldState: worldState ?? worldStateAtOrdersPhase(),
      players: [player],
    );
  }

  /// One human player `p1` with [playerStockpile], OW province `ow|p1`, and [units].
  static Game singlePlayerWorkPreviewGame({
    required Stockpile playerStockpile,
    required List<Unit> units,
    TileMapState tileState = const TileMapState(),
  }) {
    final player = Player(
      id: 'p1',
      displayName: 'A',
      isHuman: true,
      stockpile: playerStockpile,
    );
    return Game(
      id: _defaultSinglePlayerGameId,
      worldState: worldStateAtOrdersPhase(
        oldWorld: RegionData(
          units: units,
          provinces: const [
            Province(
              id: 'ow|p1',
              regionId: 'oldWorld',
              ownerId: 'p1',
              fortLevel: 0,
            ),
          ],
        ),
        tileState: tileState,
      ),
      players: [player],
    );
  }

  /// One-player game with several owned provinces in old/new world.
  static Game multiProvinceGame({
    String playerId = 'p1',
    List<Province> oldWorldProvinces = const [
      Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'p1'),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'p1'),
    ],
    List<Province> newWorldProvinces = const [
      Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'p1'),
    ],
  }) {
    return minimalGame(
      players: [
        Player(
          id: playerId,
          displayName: 'Player 1',
          isHuman: true,
          capitalProvinceId: oldWorldProvinces.first.id,
        ),
      ],
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
    );
  }

  /// One-player setup with seaboard ports and mapped owned coastal tiles.
  static Game navalGame({
    String playerId = 'p1',
    Map<String, String> portsByProvinceSeaboard = const {
      'oldWorld|harbor|north': 'oldWorld|harbor|0|0',
    },
    Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {
      'oldWorld': {
        'oldWorld|harbor': ['oldWorld|harbor|0|0'],
      },
    },
  }) {
    return minimalGame(
      players: [
        Player(id: playerId, displayName: 'Naval Player', isHuman: true),
      ],
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|harbor', regionId: 'oldWorld', ownerId: playerId),
        ],
      ),
      portsByProvinceSeaboard: portsByProvinceSeaboard,
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    );
  }

  /// One-player setup with stockpile and resources for economy tests.
  static Game economyGame({
    String playerId = 'p1',
    Stockpile stockpile = const Stockpile(
      quantities: {'food': 3, 'silver': 2},
    ),
    Map<String, String> resourceByTileKey = const {
      'oldWorld|farm|0|0': 'food',
    },
  }) {
    return minimalGame(
      players: [
        Player(
          id: playerId,
          displayName: 'Economy Player',
          isHuman: true,
          stockpile: stockpile,
        ),
      ],
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|farm', regionId: 'oldWorld', ownerId: playerId),
        ],
      ),
      resourceByTileKey: resourceByTileKey,
    );
  }

  /// Two players on shared [worldState] (default empty OW/NW, orders turn 1).
  static Game twoPlayerGame({
    required Player player1,
    required Player player2,
    String gameId = 'gid',
    WorldState? worldState,
    double richesCashMultiplier = 1.0,
  }) {
    return Game(
      id: gameId,
      worldState: worldState ?? worldStateAtOrdersPhase(),
      players: [player1, player2],
      richesCashMultiplier: richesCashMultiplier,
    );
  }

  /// Adjacent provinces with default military regiments (combat integration tests).
  static Game combatGame({
    String regionId = 'oldWorld',
    String player1Id = 'p1',
    String player2Id = 'p2',
    String localProvince1 = 'p1',
    String localProvince2 = 'p2',
    Unit? unit1,
    Unit? unit2,
  }) {
    final pid1 = '$regionId|$localProvince1';
    final pid2 = '$regionId|$localProvince2';
    final u1 = unit1 ??
        Unit(
          id: 'u1',
          type: 'grenadiers',
          ownerId: player1Id,
          locationProvinceId: pid1,
        );
    final u2 = unit2 ??
        Unit(
          id: 'u2',
          type: 'grenadiers',
          ownerId: player2Id,
          locationProvinceId: pid2,
        );
    return twoPlayerGame(
      player1: Player(
        id: player1Id,
        displayName: 'P1',
        isHuman: true,
      ),
      player2: Player(
        id: player2Id,
        displayName: 'P2',
        isHuman: false,
      ),
      worldState: worldStateAtOrdersPhase(
        oldWorld: RegionData(
          provinces: [
            Province(id: pid1, regionId: regionId, ownerId: player1Id),
            Province(id: pid2, regionId: regionId, ownerId: player2Id),
          ],
          units: [u1, u2],
        ),
      ),
    );
  }

  /// Typical civilian unit on a land province (optionally tile-addressed).
  static Unit testCivilianUnit({
    required String id,
    String type = kUnitTypeBuilder,
    String ownerId = 'p1',
    String locationProvinceId = 'oldWorld|p1',
    String? tileKey,
  }) => Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: locationProvinceId,
    tileKey: tileKey,
  );

  /// Typical military regiment on a province.
  static Unit testMilitaryUnit({
    required String id,
    String type = 'grenadiers',
    String ownerId = 'p1',
    String locationProvinceId = 'oldWorld|p1',
    int medals = 0,
  }) => Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: locationProvinceId,
    medals: medals,
  );

  /// Civilian aboard or adjacent to coastal tile (naval/boarding scenarios).
  static Unit testNavalScenarioUnit({
    required String id,
    String ownerId = 'p1',
    required String harborProvinceId,
    required String tileKey,
    String type = kUnitTypeExplorer,
  }) => Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: harborProvinceId,
    tileKey: tileKey,
  );
}
