import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared [Game] / [WorldState] factories for diplomacy package tests.
///
/// Subset of `colonizethis_logic/test/test_fixtures.dart` (Refs #3290 test migration).
abstract final class TestFixtures {
  TestFixtures._();

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
    List<Tribe> tribes = const [],
    List<OvertureState> overtureStates = const [],
    List<DiplomacyRelation> diplomacyRelations = const [],
  }) =>
      Game(
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
        tribes: tribes,
        overtureStates: overtureStates,
        diplomacyRelations: diplomacyRelations,
      );

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
