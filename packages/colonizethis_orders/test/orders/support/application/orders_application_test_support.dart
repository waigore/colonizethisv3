/// Shared constants and [Game] builders for applyBuildAndWorkOrders tests.
///
/// Refs #3877.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

abstract final class OrdersApplicationTestSupport {
  OrdersApplicationTestSupport._();

  static const ow = 'oldWorld';
  static const provinceId = '$ow|P1';
  static const tileKey = '$ow|P1|0|0';

  static const defaultPlayer = Player(
    id: 'p1',
    displayName: 'P1',
    isHuman: true,
  );

  static TileMapResult tileMapWithTerrain(TerrainType terrain) {
    return TileMapResult(
      width: 1,
      height: 1,
      grid: const [
        ['P1'],
      ],
      terrainGrid: [
        [terrain],
      ],
    );
  }

  static Stockpile stockpileCovering(Map<String, int> cost) {
    var stockpile = const Stockpile();
    for (final entry in cost.entries) {
      stockpile = stockpile.applyDelta(entry.key, entry.value);
    }
    return stockpile;
  }

  static Game workOrderApplicationGame({
    String id = 'g',
    int turnNumber = 0,
    int? globalGameSeed,
    required List<Province> provinces,
    required List<Unit> units,
    List<Player>? players,
    Map<String, String>? resourceByTileKey,
    Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
    List<MinorNation>? minorNations,
    List<OvertureState>? overtureStates,
    List<DiplomacyRelation>? diplomacyRelations,
  }) {
    return Game(
      id: id,
      globalGameSeed: globalGameSeed,
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
        oldWorld: RegionData(provinces: provinces, units: units),
        newWorld: const RegionData(),
        resourceByTileKey: resourceByTileKey ?? const {},
        tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? const {},
      ),
      players: players ?? const [defaultPlayer],
      minorNations: minorNations ?? const [],
      overtureStates: overtureStates ?? const [],
      diplomacyRelations: diplomacyRelations ?? const [],
    );
  }
}
