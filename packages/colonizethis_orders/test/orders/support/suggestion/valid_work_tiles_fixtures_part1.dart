part of 'valid_work_tiles_fixtures.dart';


Province vwtOwnedProvince(String localId) => Province(
  id: ValidWorkTilesTestSupport.provinceId(localId),
  regionId: ValidWorkTilesTestSupport.ow,
  ownerId: ValidWorkTilesTestSupport.playerId,
);

Province vwtProvince(String localId, String ownerId) => Province(
  id: ValidWorkTilesTestSupport.provinceId(localId),
  regionId: ValidWorkTilesTestSupport.ow,
  ownerId: ownerId,
);

/// Explorer on p1 — build_improvement disallowed for unit type (visibility path).
Game vwtExplorerDisallowedBuildGame() {
  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  return ValidWorkTilesTestSupport.validWorkTilesGame(
    oldWorld: RegionData(
      provinces: [vwtOwnedProvince('p1')],
      units: [
        ValidWorkTilesTestSupport.explorerUnit(
          locationProvinceId: provinceId,
          tileKey: tile,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      provinceId: [tile],
    }),
  );
}

/// Colonist on p1 with adjacent p2 — visibility filter vs plain keys parity.
Game vwtColonistVisibilityFilterGame() {
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final p2 = ValidWorkTilesTestSupport.provinceId('p2');
  final tileP1 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileP2 = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  return ValidWorkTilesTestSupport.validWorkTilesGame(
    oldWorld: RegionData(
      provinces: [vwtOwnedProvince('p1')],
      units: [
        Unit(
          id: 'u1',
          type: 'Colonist',
          ownerId: ValidWorkTilesTestSupport.playerId,
          locationProvinceId: p1,
          tileKey: tileP1,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      p1: [tileP1],
      p2: [tileP2],
    }),
  );
}

/// NW home + adjacent target province with partial visibility (home full, t0
/// unknown, t1 fogged). Used by suggest explore/prospect scenario bodies.
class NwPartialRevealHomeTarget {
  NwPartialRevealHomeTarget({
    required this.homeLocalId,
    required this.targetLocalId,
    this.homeOwnerId = ValidWorkTilesTestSupport.playerId,
    required this.targetOwnerId,
    this.unitId = 'ex1',
    this.resourceByTileKey = const {},
    this.playerProspectedTiles = const {},
  }) : provHome = ValidWorkTilesTestSupport.provinceId(
         homeLocalId,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       provTarget = ValidWorkTilesTestSupport.provinceId(
         targetLocalId,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       tileHome = ValidWorkTilesTestSupport.tileKey(
         homeLocalId,
         0,
         0,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       t0 = ValidWorkTilesTestSupport.tileKey(
         targetLocalId,
         0,
         0,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       t1 = ValidWorkTilesTestSupport.tileKey(
         targetLocalId,
         1,
         0,
         regionId: ValidWorkTilesTestSupport.nw,
       );

  final String homeLocalId;
  final String targetLocalId;
  final String homeOwnerId;
  final String targetOwnerId;
  final String unitId;
  final Map<String, String> resourceByTileKey;
  final Map<String, Set<String>> playerProspectedTiles;

  final String provHome;
  final String provTarget;
  final String tileHome;
  final String t0;
  final String t1;

  WorldState world({Unit? unit}) {
    final actor =
        unit ??
        ValidWorkTilesTestSupport.explorerUnit(
          id: unitId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
    return WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(
            id: provHome,
            regionId: ValidWorkTilesTestSupport.nw,
            ownerId: homeOwnerId,
          ),
          Province(
            id: provTarget,
            regionId: ValidWorkTilesTestSupport.nw,
            ownerId: targetOwnerId,
          ),
        ],
        units: [actor],
      ),
      tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
        {
          provHome: [tileHome],
          provTarget: [t0, t1],
        },
        regionId: ValidWorkTilesTestSupport.nw,
      ),
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: playerProspectedTiles,
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: {
          tileHome: 'fullyVisible',
          t0: 'unknown',
          t1: 'fogged',
        },
      },
    );
  }

  MapTopology topology() => MapTopology(
    nodes: [
      TopologyNode(
        id: homeLocalId,
        regionId: ValidWorkTilesTestSupport.nw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: targetLocalId,
        regionId: ValidWorkTilesTestSupport.nw,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: homeLocalId, id2: targetLocalId)],
  );

  Game game({
    required String id,
    List<Player>? players,
    List<Tribe>? tribes,
    List<MinorNation>? minorNations,
    List<OvertureState>? overtureStates,
    Unit? unit,
  }) => Game(
    id: id,
    worldState: world(unit: unit),
    players: players ?? const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: tribes ?? const [],
    minorNations: minorNations ?? const [],
    overtureStates: overtureStates ?? const [],
  );

  static NwPartialRevealHomeTarget tribeGrainIron({bool prospectedIron = false}) {
    final base = NwPartialRevealHomeTarget(
      homeLocalId: 'home',
      targetLocalId: 'tribe1',
      targetOwnerId: 'tribe1',
    );
    return NwPartialRevealHomeTarget(
      homeLocalId: 'home',
      targetLocalId: 'tribe1',
      targetOwnerId: 'tribe1',
      resourceByTileKey: {base.t0: 'grain', base.t1: 'iron'},
      playerProspectedTiles: prospectedIron
          ? {ValidWorkTilesTestSupport.playerId: {base.t1}}
          : const {},
    );
  }

  static NwPartialRevealHomeTarget minorPurchase({
    Map<String, String> resourceByTileKey = const {},
  }) {
    final base = NwPartialRevealHomeTarget(
      homeLocalId: 'own',
      targetLocalId: 'm1',
      targetOwnerId: 'minor1',
    );
    return NwPartialRevealHomeTarget(
      homeLocalId: 'own',
      targetLocalId: 'm1',
      targetOwnerId: 'minor1',
      resourceByTileKey: resourceByTileKey.isEmpty
          ? {base.t1: 'grain'}
          : resourceByTileKey,
    );
  }

  Game tribeConsulateGame(String id) => game(
        id: id,
        tribes: const [ValidWorkTilesTestSupport.defaultTribe],
        overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
      );

  Game minorPurchaseGame(String id, {List<OvertureState>? overtureStates}) =>
      game(
        id: id,
        players: [ValidWorkTilesTestSupport.playerWithTreasury()],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        overtureStates: overtureStates,
        unit: Unit(
          id: 'u1',
          type: kUnitTypeMerchant,
          ownerId: ValidWorkTilesTestSupport.playerId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        ),
      );
}

/// OW single-province builder game used by build_improvement visibility cases.
Game owBuilderVisibilityGame({
  required List<Province> provinces,
  required Map<String, List<String>> tilesByProvince,
  required Map<String, String> resourceByTileKey,
  required String builderTileKey,
  String builderProvinceLocalId = 'p1',
  Map<String, String>? purchasedTilesByTileKey,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, int>? improvementByTile,
  List<Player>? extraPlayers,
  List<MinorNation>? minorNations,
  String? seaZoneId,
  List<String>? seaTiles,
}) {
  final p1 = ValidWorkTilesTestSupport.provinceId(builderProvinceLocalId);
  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1,
    tileKey: builderTileKey,
  );
  final tileKeys = Map<String, List<String>>.from(tilesByProvince);
  if (seaZoneId != null && seaTiles != null) {
    tileKeys[seaZoneId] = seaTiles;
  }
  final visibility = <String, String>{
    for (final tiles in tileKeys.values)
      for (final t in tiles) t: 'fullyVisible',
  };
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: [unit]),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: seaZoneId == null
          ? ValidWorkTilesTestSupport.tileKeysByProvince(tilesByProvince)
          : {ValidWorkTilesTestSupport.ow: tileKeys},
      resourceByTileKey: resourceByTileKey,
      purchasedTilesByTileKey: purchasedTilesByTileKey ?? const {},
      playerProspectedTiles: playerProspectedTiles ?? const {},
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: visibility,
      },
      tileState: TileMapState(
        improvementByTile: improvementByTile ?? const {},
      ),
    ),
    players: [
      ValidWorkTilesTestSupport.playerWithBuildStockpile(),
      ...?extraPlayers,
    ],
    minorNations: minorNations ?? const [],
  );
}

/// Tribe-owned OW province explorer setup for prospect tile-key cases.
Game owTribeProspectGame({
  required String provinceLocalId,
  required List<String> tileKeys,
  required Map<String, String> resourceByTileKey,
  required Map<String, String> visibilityByTile,
  Map<String, Set<String>>? playerProspectedTiles,
}) {
  final provinceId = ValidWorkTilesTestSupport.provinceId(provinceLocalId);
  final startTile = tileKeys.first;
  final unit = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: provinceId,
    tileKey: startTile,
  );
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: ValidWorkTilesTestSupport.ow,
            ownerId: 'tribe1',
          ),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: visibilityByTile,
      },
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: playerProspectedTiles ?? const {},
      tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
        provinceId: tileKeys,
      }),
    ),
    players: const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
}

MapTopology owSingleProvinceTopology(String localId) => MapTopology(
  nodes: [
    TopologyNode(
      id: localId,
      regionId: ValidWorkTilesTestSupport.ow,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);
