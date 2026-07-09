part of 'order_engine_validate_work_fixtures.dart';

Province _vwProvince({
  required String provinceId,
  required String ow,
  int fortLevel = 0,
  String? townTileKey,
  int? townDevelopmentLevel,
}) =>
    Province(
      id: provinceId,
      regionId: ow,
      ownerId: 'p1',
      fortLevel: fortLevel,
      townTileKey: townTileKey,
      townDevelopmentLevel: townDevelopmentLevel ?? kTownDevelopmentLevelMin,
    );

Game vwSingleProvinceUnitGame({
  required String unitId,
  required String unitType,
  Map<String, String>? resourceByTileKey,
  TileMapState tileState = const TileMapState(),
  Map<String, bool>? techUnlocked,
  Stockpile? stockpile,
  Map<String, Set<String>>? playerProspectedTiles,
  int fortLevel = 0,
  String? townTileKey,
  int? townDevelopmentLevel,
  List<String>? extraTileKeys,
  int turnNumber = 0,
}) {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final tileKeys = [tileKey, ...?extraTileKeys];
  final visibility = {
    for (final key in tileKeys) key: 'fullyVisible',
  };
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          _vwProvince(
            provinceId: provinceId,
            ow: ow,
            fortLevel: fortLevel,
            townTileKey: townTileKey,
            townDevelopmentLevel: townDevelopmentLevel,
          ),
        ],
        units: [
          Unit(
            id: unitId,
            type: unitType,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey ?? const {},
      tileState: tileState,
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: tileKeys,
        },
      },
      playerVisibilityByTile: {
        'p1': visibility,
      },
      playerProspectedTiles: playerProspectedTiles ?? const {},
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: stockpile ?? const Stockpile(),
        techUnlocked: techUnlocked ?? const {},
      ),
    ],
  );
}

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
  const tileB = '${ValidateWorkOw.provinceId}|1|0';
  const tileA = ValidateWorkOw.tileKey;
  return vwSingleProvinceUnitGame(
    unitId: 'builder1',
    unitType: kUnitTypeBuilder,
    extraTileKeys: [tileB],
    resourceByTileKey: const {tileA: 'grain', tileB: 'grain'},
    stockpile: lumberCastIronStockpile(20),
    techUnlocked: const {kTechIdCircularSaw: true},
    turnNumber: 1,
  );
}

Game builderEngineerSameTileExclusivityGame() {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: const [
          Province(id: provinceId, regionId: ow, ownerId: 'p1'),
        ],
        units: [
          Unit(
            id: 'builder1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
          Unit(
            id: 'engineer1',
            type: kUnitTypeEngineer,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {tileKey: 'grain'},
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: const {
        ow: {
          provinceId: [tileKey],
        },
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: lumberCastIronStockpile(10),
      ),
    ],
  );
}

Game minorProvinceEngineerRoadGame({List<OvertureState>? overtureStates}) {
  const ow = ValidateWorkOw.ow;
  const minorProvId = '$ow|MN';
  const tileKey = '$minorProvId|0|0';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: minorProvId, regionId: ow, ownerId: 'minor1')],
        units: [
          Unit(
            id: 'e1',
            type: kUnitTypeEngineer,
            ownerId: 'gp1',
            locationProvinceId: minorProvId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          minorProvId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'gp1': {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: true,
        capitalProvinceId: '$ow|CAP',
        stockpile: lumberCastIronStockpile(4),
        techUnlocked: const {kTechIdDiplomaticExpertise: true},
      ),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'minor1',
        state: RelationState.atPeace,
        level: RelationLevel.neutral,
      ),
    ],
    overtureStates: overtureStates ?? const [],
  );
}

MapTopology minorProvinceRoadTopology() {
  const ow = ValidateWorkOw.ow;
  return const MapTopology(
    nodes: [
      TopologyNode(id: 'MN', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: [],
  );
}

Game upgradeTownWorkGame({required Map<String, bool> techUnlocked}) {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: ow,
            ownerId: 'p1',
            townTileKey: tileKey,
            townDevelopmentLevel: 1,
          ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
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
        stockpile: lumberCastIronStockpile(10),
        techUnlocked: techUnlocked,
      ),
    ],
  );
}
