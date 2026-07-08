// Shared fixtures for OrderEngine validateWork scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared OW province/tile constants for validateWork family tests.
abstract final class ValidateWorkOw {
  static const ow = 'oldWorld';
  static const provinceId = '$ow|P1';
  static const tileKey = '$provinceId|0|0';

  static MapTopology topology() => const MapTopology(
    nodes: [
      TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: [],
  );
}

Game buildImprovementBaseGame({
  Map<String, String>? resourceByTileKey,
  TileMapState tileState = const TileMapState(),
  Map<String, bool>? techUnlocked,
  Stockpile? stockpile,
  Map<String, Set<String>>? playerProspectedTiles,
}) {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [
          Unit(
            id: 'builder1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey ?? {tileKey: 'grain'},
      tileState: tileState,
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
      playerProspectedTiles: playerProspectedTiles ?? const {},
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile:
            stockpile ??
            Stockpile()
                .applyDelta(CommodityCatalog.lumber.id, 2)
                .applyDelta(CommodityCatalog.castIron.id, 2),
        techUnlocked: techUnlocked ?? const {kTechIdCircularSaw: true},
      ),
    ],
  );
}

Map<String, TileMapResult> scrubCapTileMaps(TerrainType terrain) {
  const ow = ValidateWorkOw.ow;
  return {
    ow: TileMapResult(
      width: 1,
      height: 1,
      grid: const [
        ['P1'],
      ],
      terrainGrid: [
        [terrain],
      ],
      resourceGrid: const [
        [Resource.timber],
      ],
    ),
  };
}

Game scrubCapBaseGame({required int level}) {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [
          Unit(
            id: 'builder1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {tileKey: 'timber'},
      tileState: TileMapState(improvementByTile: {tileKey: level}),
      tileKeysByRegionAndProvince: const {
        ow: {
          provinceId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 20)
            .applyDelta(CommodityCatalog.castIron.id, 20),
        techUnlocked: const {
          kTechIdSawMill: true,
          kTechIdWindSawMill: true,
          kTechIdCircularSaw: true,
        },
      ),
    ],
  );
}

TileMapResult railTileMap(TerrainType terrain) => TileMapResult(
  width: 1,
  height: 1,
  grid: const [
    ['P1'],
  ],
  terrainGrid: [
    [terrain],
  ],
);

Stockpile railStockpile() => Stockpile()
    .applyDelta(CommodityCatalog.lumber.id, 10)
    .applyDelta(CommodityCatalog.steel.id, 10);

Game gameWithRailUnit({
  required TileMapState tileState,
  Map<String, bool>? techUnlocked,
  Stockpile? stockpile,
}) {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [
          Unit(
            id: 'rail1',
            type: kUnitTypeRailBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: stockpile ?? railStockpile(),
        techUnlocked: techUnlocked ?? const {kTechIdEarlySteamEngine: true},
      ),
    ],
  );
}
