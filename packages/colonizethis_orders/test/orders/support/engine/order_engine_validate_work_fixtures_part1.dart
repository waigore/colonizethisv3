part of 'order_engine_validate_work_fixtures.dart';

Game buildImprovementBaseGame({
  Map<String, String>? resourceByTileKey,
  TileMapState tileState = const TileMapState(),
  Map<String, bool>? techUnlocked,
  Stockpile? stockpile,
  Map<String, Set<String>>? playerProspectedTiles,
}) {
  const tileKey = ValidateWorkOw.tileKey;
  return vwSingleProvinceUnitGame(
    unitId: 'builder1',
    unitType: kUnitTypeBuilder,
    resourceByTileKey: resourceByTileKey ?? {tileKey: 'grain'},
    tileState: tileState,
    techUnlocked: techUnlocked ?? const {kTechIdCircularSaw: true},
    stockpile:
        stockpile ??
        Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 2)
            .applyDelta(CommodityCatalog.castIron.id, 2),
    playerProspectedTiles: playerProspectedTiles,
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
  const tileKey = ValidateWorkOw.tileKey;
  return vwSingleProvinceUnitGame(
    unitId: 'builder1',
    unitType: kUnitTypeBuilder,
    resourceByTileKey: {tileKey: 'timber'},
    tileState: TileMapState(improvementByTile: {tileKey: level}),
    stockpile: lumberCastIronStockpile(20),
    techUnlocked: const {
      kTechIdSawMill: true,
      kTechIdWindSawMill: true,
      kTechIdCircularSaw: true,
    },
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
}) =>
    vwSingleProvinceUnitGame(
      unitId: 'rail1',
      unitType: kUnitTypeRailBuilder,
      tileState: tileState,
      stockpile: stockpile ?? railStockpile(),
      techUnlocked: techUnlocked ?? const {kTechIdEarlySteamEngine: true},
    );

Game buildImprovementForeignProvinceGame({
  Map<String, String>? purchasedTilesByTileKey,
}) {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final foreignProvinceId = '$ow|P2';
  final foreignTileKey = '$foreignProvinceId|0|0';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          Province(id: foreignProvinceId, regionId: ow, ownerId: 'p2'),
        ],
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
      resourceByTileKey: {tileKey: 'grain', foreignTileKey: 'grain'},
      tileState: const TileMapState(),
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
          foreignProvinceId: [foreignTileKey],
        },
      },
      playerVisibilityByTile: {
        'p1': {tileKey: 'fullyVisible', foreignTileKey: 'fullyVisible'},
      },
      purchasedTilesByTileKey: purchasedTilesByTileKey ?? const {},
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 2)
            .applyDelta(CommodityCatalog.castIron.id, 2),
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
      const Player(id: 'p2', displayName: 'P2', isHuman: false),
    ],
  );
}

String validateWorkForeignTileKey() => '${ValidateWorkOw.ow}|P2|0|0';

Game fortWorkGame({
  required int fortLevel,
  required Stockpile stockpile,
  Map<String, bool>? techUnlocked,
}) =>
    vwSingleProvinceUnitGame(
      unitId: 'eng1',
      unitType: kUnitTypeEngineer,
      fortLevel: fortLevel,
      stockpile: stockpile,
      techUnlocked: techUnlocked,
    );

Game dualTilePendingWorkGame() {
  const regionId = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileA = ValidateWorkOw.tileKey;
  const tileB = '$provinceId|1|0';
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: regionId, ownerId: 'p1'),
        ],
        units: [
          Unit(
            id: 'builder1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileA,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        regionId: {
          provinceId: [tileA, tileB],
        },
      },
      resourceByTileKey: const {tileA: 'grain', tileB: 'grain'},
      playerVisibilityByTile: const {
        'p1': {tileA: 'fullyVisible', tileB: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: lumberCastIronStockpile(20),
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
    ],
  );
}
