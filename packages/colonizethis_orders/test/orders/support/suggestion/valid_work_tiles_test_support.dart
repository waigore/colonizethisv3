/// Shared constants and [Game] builders for getValidWorkOrderTileKeys tests.
///
/// Refs #3877.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

abstract final class ValidWorkTilesTestSupport {
  ValidWorkTilesTestSupport._();

  static const ow = 'oldWorld';
  static const nw = 'newWorld';
  static const playerId = 'gp1';
  static const emptyTopology = MapTopology(nodes: [], edges: []);

  static const defaultPlayer = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
  );

  static const defaultTribe = Tribe(id: 'tribe1', displayName: 'Tribe');

  static const tribeConsulateOverture = OvertureState(
    gpId: playerId,
    targetId: 'tribe1',
    stage: OvertureStage.tradeConsulate,
  );

  static OvertureState embassyOverture({
    String targetId = 'minor1',
    int sinceTurn = 0,
  }) =>
      OvertureState(
        gpId: playerId,
        targetId: targetId,
        stage: OvertureStage.embassy,
        sinceTurn: sinceTurn,
      );

  static Map<String, Map<String, List<String>>> tileKeysByProvince(
    Map<String, List<String>> provinceTiles, {
    String regionId = ow,
  }) =>
      {regionId: provinceTiles};

  static String provinceId(String localId, {String regionId = ow}) =>
      '$regionId|$localId';

  static String tileKey(
    String localId,
    int x,
    int y, {
    String regionId = ow,
  }) =>
      '$regionId|$localId|$x|$y';

  static Unit explorerUnit({
    String id = 'u1',
    String ownerId = playerId,
    required String locationProvinceId,
    String? tileKey,
  }) =>
      Unit(
        id: id,
        type: kUnitTypeExplorer,
        ownerId: ownerId,
        locationProvinceId: locationProvinceId,
        tileKey: tileKey,
      );

  static Unit builderUnit({
    String id = 'u1',
    String ownerId = playerId,
    required String locationProvinceId,
    String? tileKey,
  }) =>
      Unit(
        id: id,
        type: kUnitTypeBuilder,
        ownerId: ownerId,
        locationProvinceId: locationProvinceId,
        tileKey: tileKey,
      );

  static Player playerWithTreasury({int treasury = 500}) => Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: treasury,
      );

  static Player playerWithBuildStockpile() => Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
      );

  static Game minimalValidWorkTilesGame({
    String id = 'g1',
    RegionData? oldWorld,
    Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
    List<Player>? players,
    List<Tribe>? tribes,
    List<OvertureState>? overtureStates,
    Map<String, Map<String, String>>? playerVisibilityByTile,
  }) =>
      TestFixtures.minimalGame(
        id: id,
        players: players ?? const [defaultPlayer],
        tribes: tribes ?? const [],
        overtureStates: overtureStates ?? const [],
        oldWorld: oldWorld ?? const RegionData(provinces: [], units: []),
        tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? const {},
        playerVisibilityByTile: playerVisibilityByTile,
      );

  static Game validWorkTilesGame({
    String id = 'g1',
    int turnNumber = 1,
    required RegionData oldWorld,
    Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
    List<Player>? players,
    List<Tribe>? tribes,
    List<OvertureState>? overtureStates,
    Map<String, Map<String, String>>? playerVisibilityByTile,
  }) =>
      Game(
        id: id,
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
          oldWorld: oldWorld,
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince:
              tileKeysByRegionAndProvince ?? const {},
          playerVisibilityByTile: playerVisibilityByTile ?? const {},
        ),
        players: players ?? const [defaultPlayer],
        tribes: tribes ?? const [],
        overtureStates: overtureStates ?? const [],
      );
}
