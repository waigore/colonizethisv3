import 'package:colonizethis_models/colonizethis_models.dart';

import 'test_fixtures_world_state.dart';

/// Sole in-package [Game] construction seam for [TestFixtures].
abstract final class TestFixturesGameCore {
  TestFixturesGameCore._();

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
    int nextArmySeq = 1,
    List<Fleet> fleets = const [],
    Map<String, Map<String, int>> spyRevealTurnsByPlayer = const {},
    Map<String, String> seaZoneDisplayNameById = const {},
    int nextShipInstanceSeq = 1,
    double richesCashMultiplier = 1.0,
    int capitalTileGrainBonusPerTurn = 5,
    List<MinorNation> minorNations = const [],
    List<Tribe> tribes = const [],
    List<OvertureState> overtureStates = const [],
    List<DiplomacyRelation> diplomacyRelations = const [],
    List<General> generals = const [],
    List<SubsidyState> subsidyStates = const [],
    List<ColonyState> colonyStates = const [],
    List<BoycottState> boycottStates = const [],
    WorldMarketState worldMarketState = WorldMarketState.empty,
    WorldState? worldState,
  }) =>
      Game(
        id: id,
        capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
        worldState: worldState ??
            TestFixturesWorldState.worldStateForGame(
              phase: phase,
              turnNumber: turnNumber,
              oldWorld: oldWorld,
              newWorld: newWorld,
              tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
              playerVisibilityByTile: playerVisibilityByTile,
              resourceByTileKey: resourceByTileKey,
              purchasedTilesByTileKey: purchasedTilesByTileKey,
              portsByProvinceSeaboard: portsByProvinceSeaboard,
              playerProspectedTiles: playerProspectedTiles,
              tileState: tileState,
              armies: armies,
              nextArmySeq: nextArmySeq,
              fleets: fleets,
              spyRevealTurnsByPlayer: spyRevealTurnsByPlayer,
              seaZoneDisplayNameById: seaZoneDisplayNameById,
              nextShipInstanceSeq: nextShipInstanceSeq,
            ),
        players: players,
        richesCashMultiplier: richesCashMultiplier,
        minorNations: minorNations,
        tribes: tribes,
        overtureStates: overtureStates,
        diplomacyRelations: diplomacyRelations,
        generals: generals,
        subsidyStates: subsidyStates,
        colonyStates: colonyStates,
        boycottStates: boycottStates,
        worldMarketState: worldMarketState,
      );
}
