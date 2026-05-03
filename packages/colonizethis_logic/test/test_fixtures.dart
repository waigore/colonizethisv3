import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared [Game] / [WorldState] factories for logic package tests.
///
/// Refs waigore/colonizethis#2071 (centralize repeated setup).
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
    double richesCashMultiplier = 1.0,
    List<MinorNation> minorNations = const [],
    List<OvertureState> overtureStates = const [],
    List<DiplomacyRelation> diplomacyRelations = const [],
  }) => Game(
    id: id,
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
    ),
    players: players,
    richesCashMultiplier: richesCashMultiplier,
    minorNations: minorNations,
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
}
