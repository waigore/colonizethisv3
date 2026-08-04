import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// 1×1 OW [TileMapResult] keyed by [kRegionOldWorld].
Map<String, TileMapResult> turnTestSingleTileOwMap(
  String provinceLocalId, {
  TerrainType terrain = TerrainType.hills,
}) {
  return {
    kRegionOldWorld: TileMapResult(
      width: 1,
      height: 1,
      grid: [
        [provinceLocalId],
      ],
      terrainGrid: [
        [terrain],
      ],
    ),
  };
}

/// 1×1 tile map with a resource grid cell.
TileMapResult turnTestResourceTileMap(String localId, Resource resource) {
  return TileMapResult(
    width: 1,
    height: 1,
    grid: [
      [localId],
    ],
    resourceGrid: [
      [resource],
    ],
  );
}

/// Single OW province [Game] with optional stockpile/treasury on the lone player.
Game turnTestOwSingleProvinceGame({
  String ownerId = 'p1',
  Stockpile? stockpile,
  int treasury = 0,
  List<Unit> units = const [],
}) {
  const ow = kRegionOldWorld;
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: ownerId),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: ownerId,
        displayName: 'P1',
        isHuman: true,
        treasury: treasury,
        stockpile: stockpile ?? Stockpile.empty,
      ),
    ],
  );
}
