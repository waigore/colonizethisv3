import 'package:colonizethis_models/colonizethis_models.dart';

/// World-state construction seam for [TestFixtures].
abstract final class TestFixturesWorldState {
  TestFixturesWorldState._();

  /// Both regions empty; tunable turn.
  static WorldState emptyWorldState({
    TurnPhase phase = TurnPhase.orders,
    int turnNumber = 1,
  }) =>
      WorldState(
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
    Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
        const {},
    List<Army> armies = const [],
    int nextArmySeq = 1,
    List<Fleet> fleets = const [],
    Map<String, Map<String, int>> spyRevealTurnsByPlayer = const {},
    Map<String, Map<String, String>>? playerVisibilityByTile,
    Map<String, String>? resourceByTileKey,
    Map<String, String>? purchasedTilesByTileKey,
    Map<String, String>? portsByProvinceSeaboard,
    Map<String, Set<String>>? playerProspectedTiles,
    Map<String, String> seaZoneDisplayNameById = const {},
    int nextShipInstanceSeq = 1,
  }) {
    return WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: oldWorld ?? const RegionData(),
      newWorld: newWorld ?? const RegionData(),
      tileState: tileState ?? const TileMapState(),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      armies: armies,
      nextArmySeq: nextArmySeq,
      fleets: fleets,
      spyRevealTurnsByPlayer: spyRevealTurnsByPlayer,
      playerVisibilityByTile: playerVisibilityByTile ?? const {},
      resourceByTileKey: resourceByTileKey ?? const {},
      purchasedTilesByTileKey: purchasedTilesByTileKey ?? const {},
      portsByProvinceSeaboard: portsByProvinceSeaboard ?? const {},
      playerProspectedTiles: playerProspectedTiles ?? const {},
      seaZoneDisplayNameById: seaZoneDisplayNameById,
      nextShipInstanceSeq: nextShipInstanceSeq,
    );
  }

  /// Tunable turn phase for [TestFixturesGameCore.minimalGame].
  static WorldState worldStateForGame({
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
    int nextArmySeq = 1,
    List<Fleet> fleets = const [],
    Map<String, Map<String, int>> spyRevealTurnsByPlayer = const {},
    Map<String, String> seaZoneDisplayNameById = const {},
    int nextShipInstanceSeq = 1,
  }) =>
      WorldState(
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
        nextArmySeq: nextArmySeq,
        fleets: fleets,
        spyRevealTurnsByPlayer: spyRevealTurnsByPlayer,
        seaZoneDisplayNameById: seaZoneDisplayNameById,
        nextShipInstanceSeq: nextShipInstanceSeq,
      );
}
