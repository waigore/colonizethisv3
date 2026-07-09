part of 'order_engine_validate_work_fixtures.dart';

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
