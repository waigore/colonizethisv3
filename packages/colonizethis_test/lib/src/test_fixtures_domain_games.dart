import 'package:colonizethis_models/colonizethis_models.dart';

import 'test_fixtures_game_core.dart';
import 'test_fixtures_world_state.dart';

/// Domain-scenario [Game] factories for [TestFixtures].
abstract final class TestFixturesDomainGames {
  TestFixturesDomainGames._();

  static const String defaultSinglePlayerGameId = 't';

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
  }) =>
      TestFixturesGameCore.minimalGame(
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
  }) =>
      TestFixturesGameCore.minimalGame(
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
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: ownerPlayerId,
            ),
          ],
        ),
      );

  /// Minimal [Game] with one [player] and empty both regions.
  static Game singlePlayerGame(
    Player player, {
    String gameId = defaultSinglePlayerGameId,
    WorldState? worldState,
  }) =>
      TestFixturesGameCore.minimalGame(
        id: gameId,
        players: [player],
        worldState: worldState,
      );

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
    return TestFixturesGameCore.minimalGame(
      id: defaultSinglePlayerGameId,
      players: [player],
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
  }) =>
      TestFixturesGameCore.minimalGame(
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
  }) =>
      TestFixturesGameCore.minimalGame(
        players: [
          Player(id: playerId, displayName: 'Naval Player', isHuman: true),
        ],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|harbor',
              regionId: 'oldWorld',
              ownerId: playerId,
            ),
          ],
        ),
        portsByProvinceSeaboard: portsByProvinceSeaboard,
        tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      );

  /// One-player setup with stockpile and resources for economy tests.
  static Game economyGame({
    String playerId = 'p1',
    Stockpile stockpile = const Stockpile(
      quantities: {'food': 3, 'silver': 2},
    ),
    Map<String, String> resourceByTileKey = const {
      'oldWorld|farm|0|0': 'food',
    },
  }) =>
      TestFixturesGameCore.minimalGame(
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
            Province(
              id: 'oldWorld|farm',
              regionId: 'oldWorld',
              ownerId: playerId,
            ),
          ],
        ),
        resourceByTileKey: resourceByTileKey,
      );

  /// Two players on shared [worldState] (default empty OW/NW, orders turn 1).
  static Game twoPlayerGame({
    required Player player1,
    required Player player2,
    String gameId = 'gid',
    WorldState? worldState,
    double richesCashMultiplier = 1.0,
  }) =>
      TestFixturesGameCore.minimalGame(
        id: gameId,
        players: [player1, player2],
        richesCashMultiplier: richesCashMultiplier,
        worldState: worldState,
      );
}
