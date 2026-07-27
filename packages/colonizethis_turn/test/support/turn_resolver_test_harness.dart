import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Old World region id for two-province integration setups in turn tests.
const turnTestOldWorldRegionId = kRegionOldWorld;

/// 1×1 tile key in Old World for [localProvinceId] (e.g. `P2` → `oldWorld|P2|0|0`).
String turnTestOwTileKey(String localProvinceId) =>
    '${turnTestOldWorldRegionId}|$localProvinceId|0|0';

/// 1×1 tile key in New World for [localProvinceId].
String turnTestNwTileKey(String localProvinceId) =>
    '${kRegionNewWorld}|$localProvinceId|0|0';

/// Standard carrack [Fleet] for naval integration scenarios.
Fleet turnTestCarrackFleet({
  String id = 'f1',
  String ownerId = 'p1',
  String? seaZoneId = 'sea1',
  String? inPortAtProvinceId,
  String regionId = kRegionOldWorld,
  FleetMission mission = FleetMission.none,
  List<String> shipTypeIds = const ['carrack'],
}) {
  return Fleet(
    id: id,
    ownerId: ownerId,
    seaZoneId: seaZoneId,
    inPortAtProvinceId: inPortAtProvinceId,
    regionId: regionId,
    shipTypeIds: shipTypeIds,
    mission: mission,
  );
}

/// Fixed [Game.globalGameSeed] for spy/fog integration tests so spy-resolution
/// kill rolls stay deterministic (unset seed uses [Random] per
/// [spyPhaseRandom]).
const turnTestSpyFogGameSeed = 42;

/// Two Old World provinces; when [adjacent] is true they share a topology edge.
MapTopology twoAdjacentOldWorldProvinceTopology({
  String id1 = 'P1',
  String id2 = 'P2',
  String regionId = turnTestOldWorldRegionId,
  bool adjacent = true,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: id1,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: id2,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: adjacent
        ? [TopologyEdge(id1: id1, id2: id2)]
        : const <TopologyEdge>[],
  );
}

/// Prefixed Old World province id for [adjacentOwP1P2Game] setups (`oldWorld|P1`).
String turnTestOwProvinceId(String localId) =>
    '$turnTestOldWorldRegionId|$localId';

/// One owner block in [turnTestOwProvinceStacksFixture] (local ids `prefix0`…).
typedef TurnTestOwProvinceStack = ({
  String ownerId,
  int count,
  String localIdPrefix,
});

/// OW [Game] + province-only [MapTopology] from stacked owner blocks.
///
/// Used by military-victory integration scenarios (mass-province maps).
({Game game, MapTopology topology}) turnTestOwProvinceStacksFixture({
  required List<TurnTestOwProvinceStack> stacks,
  int turnNumber = 0,
  List<Player>? players,
  String gameId = 'g1',
}) {
  const ow = turnTestOldWorldRegionId;
  final provinces = <Province>[];
  final nodes = <TopologyNode>[];
  for (final stack in stacks) {
    for (var i = 0; i < stack.count; i++) {
      final localId = '${stack.localIdPrefix}$i';
      provinces.add(
        Province(id: '$ow|$localId', regionId: ow, ownerId: stack.ownerId),
      );
      nodes.add(
        TopologyNode(
          id: localId,
          regionId: ow,
          type: TopologyNodeType.province,
        ),
      );
    }
  }
  final game = Game(
    id: gameId,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players:
        players ??
        const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
  );
  return (
    game: game,
    topology: MapTopology(nodes: nodes, edges: const []),
  );
}

/// Adjacent OW `P1`/`P2` game with empty New World.
///
/// Pair with [twoAdjacentOldWorldProvinceTopology] (topology stays separate).
/// Cross-region, sea/fleet, and mass-province maps stay hand-rolled.
Game adjacentOwP1P2Game({
  String id = 'g1',
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 0,
  String province1OwnerId = 'p1',
  String province2OwnerId = 'p2',
  List<Unit> units = const [],
  List<Player>? players,
  int? globalGameSeed,
  CombatMode? defaultCombatMode,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  TileMapState? tileState,
  bool ensureMilitaryArmies = false,
}) {
  const ow = turnTestOldWorldRegionId;
  final game = Game(
    id: id,
    globalGameSeed: globalGameSeed,
    defaultCombatMode: defaultCombatMode,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: province1OwnerId),
          Province(id: '$ow|P2', regionId: ow, ownerId: province2OwnerId),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: playerVisibilityByTile ?? const {},
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? const {},
      tileState: tileState ?? const TileMapState(),
    ),
    players:
        players ??
        const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
  );
  return ensureMilitaryArmies ? ensureMilitaryArmiesForGame(game) : game;
}

/// Runs [resolveTurnForGame] and returns the resolved [Game], failing on pending.
Game resolveTurnComplete({
  required Game game,
  required MapTopology topology,
  Orders orders = const Orders(),
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  TurnEventSink? eventSink,
  TurnPhase? startFromPhase,
}) {
  return requireTurnResolutionComplete(
    resolveTurnForGame(
      game: game,
      topology: topology,
      orders: orders,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      extractedByPlayerId: extractedByPlayerId,
      defaultAssignments: defaultAssignments,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      eventSink: eventSink,
      startFromPhase: startFromPhase,
    ),
  );
}

/// OW sea zone plus one province; optionally linked by a topology edge.
MapTopology turnTestOwSeaProvinceTopology({
  String seaZoneId = 'sea1',
  String provinceLocalId = 'P1',
  bool linkSeaToProvince = true,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: seaZoneId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: provinceLocalId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
    ],
    edges: linkSeaToProvince
        ? [TopologyEdge(id1: seaZoneId, id2: provinceLocalId)]
        : const <TopologyEdge>[],
  );
}

/// OW sea zone only (no provinces).
MapTopology turnTestOwSeaZoneTopology({String seaZoneId = 'sea1'}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: seaZoneId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [],
  );
}

/// Two linked OW sea zones (default `sea1`–`sea2`).
MapTopology turnTestOwTwoLinkedSeaZonesTopology({
  String seaZone1 = 'sea1',
  String seaZone2 = 'sea2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: seaZone1,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: seaZone2,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: seaZone1, id2: seaZone2)],
  );
}

/// [Game] with fleets only (empty province data).
Game turnTestFleetsOnlyGame({
  required List<Fleet> fleets,
  List<Player>? players,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players:
        players ?? const [Player(id: 'p1', displayName: 'A', isHuman: true)],
  );
}

/// Single OW province topology (no sea).
MapTopology turnTestOwSingleProvinceTopology({String provinceLocalId = 'P1'}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: provinceLocalId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
}

/// Two-province OW + NW cross-region topology (no edges).
MapTopology turnTestOwNwCrossRegionTopology({
  String owProvinceLocalId = 'P1',
  String nwProvinceLocalId = 'P2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: owProvinceLocalId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: nwProvinceLocalId,
        regionId: kRegionNewWorld,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
}

/// Minimal OW [Game] with provinces and optional fleets / diplomacy.
Game turnTestOwGame({
  String id = 'g1',
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 0,
  required List<Province> provinces,
  List<Fleet> fleets = const [],
  List<Player>? players,
  List<DiplomacyRelation>? diplomacyRelations,
  List<Unit> units = const [],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces, units: units),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players:
        players ??
        const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
    diplomacyRelations: diplomacyRelations ?? const [],
  );
}

/// Two adjacent OW provinces owned by [owner1Id] / [owner2Id].
List<Province> turnTestOwP1P2Provinces({
  String owner1Id = 'p1',
  String owner2Id = 'p2',
}) {
  return [
    Province(
      id: turnTestOwProvinceId('P1'),
      regionId: kRegionOldWorld,
      ownerId: owner1Id,
    ),
    Province(
      id: turnTestOwProvinceId('P2'),
      regionId: kRegionOldWorld,
      ownerId: owner2Id,
    ),
  ];
}

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

/// OW+NW cross-region [Game] with one owned province per region.
Game turnTestOwNwCrossRegionGame({
  String ownerId = 'p1',
  List<Unit> owUnits = const [],
  List<Unit> nwUnits = const [],
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
}) {
  const ow = kRegionOldWorld;
  const nw = kRegionNewWorld;
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: ownerId),
        ],
        units: owUnits,
      ),
      newWorld: RegionData(
        provinces: [
          Province(id: '$nw|P2', regionId: nw, ownerId: ownerId),
        ],
        units: nwUnits,
      ),
      playerVisibilityByTile: playerVisibilityByTile ?? const {},
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? const {},
    ),
    players: [Player(id: ownerId, displayName: 'A', isHuman: true)],
  );
}

/// OW+NW [Game] with same local id `P1` in both regions for spy/fog decay tests.
Game turnTestSpyFogOwNwSameLocalIdGame({
  int turnNumber = 1,
  TurnPhase phase = TurnPhase.endOfTurn,
  List<Unit> owUnits = const [],
}) {
  const ow = kRegionOldWorld;
  const nw = kRegionNewWorld;
  const tileKeyOwP1 = 'oldWorld|P1|0|0';
  const tileKeyNwP1 = 'newWorld|P1|0|0';
  return Game(
    id: 'g1',
    globalGameSeed: turnTestSpyFogGameSeed,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p2'),
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
        ],
        units: owUnits,
      ),
      newWorld: RegionData(
        provinces: [
          Province(id: '$nw|P1', regionId: nw, ownerId: 'p2'),
        ],
      ),
      playerVisibilityByTile: {
        'p1': {
          tileKeyOwP1: VisibilityLevel.fullyVisible.name,
          tileKeyNwP1: VisibilityLevel.fullyVisible.name,
        },
        'p2': {},
      },
      tileKeysByRegionAndProvince: {
        ow: {
          'P1': [tileKeyOwP1],
          'P2': ['oldWorld|P2|0|0'],
        },
        nw: {
          'P1': [tileKeyNwP1],
        },
      },
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: false),
    ],
  );
}

/// Topology for [turnTestSpyFogOwNwSameLocalIdGame] (three provinces, no edges).
MapTopology turnTestSpyFogOwNwSameLocalIdTopology() {
  const ow = kRegionOldWorld;
  const nw = kRegionNewWorld;
  return MapTopology(
    nodes: const [
      TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: 'P1', regionId: nw, type: TopologyNodeType.province),
    ],
    edges: const [],
  );
}

/// OW minor + NW tribe combat [Game] for reactive dialogue integration tests.
Game turnTestOwNwMinorTribeAttackGame() {
  const ow = kRegionOldWorld;
  const nw = kRegionNewWorld;
  return ensureMilitaryArmiesForGame(
    Game(
      id: 'g1',
      globalGameSeed: 99,
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: const [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'human'),
            Province(id: '$ow|P2', regionId: ow, ownerId: 'mn1'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'grenadiers',
              ownerId: 'human',
              locationProvinceId: '$ow|P1',
            ),
            Unit(
              id: 'm1',
              type: 'peasant_levies',
              ownerId: 'mn1',
              locationProvinceId: '$ow|P2',
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: const [
            Province(id: '$nw|N1', regionId: nw, ownerId: 'human'),
            Province(id: '$nw|N2', regionId: nw, ownerId: 'tr1'),
          ],
          units: [
            Unit(
              id: 'u2',
              type: 'grenadiers',
              ownerId: 'human',
              locationProvinceId: '$nw|N1',
            ),
            Unit(
              id: 't1',
              type: 'peasant_levies',
              ownerId: 'tr1',
              locationProvinceId: '$nw|N2',
            ),
          ],
        ),
      ),
      players: const [
        Player(id: 'human', displayName: 'Human', isHuman: true),
        Player(id: 'ai1', displayName: 'AI', isHuman: false),
      ],
      minorNations: const [MinorNation(id: 'mn1')],
      tribes: const [Tribe(id: 'tr1')],
      overtureStates: const [
        OvertureState(
          gpId: 'ai1',
          targetId: 'mn1',
          stage: OvertureStage.embassy,
        ),
        OvertureState(
          gpId: 'ai1',
          targetId: 'tr1',
          stage: OvertureStage.embassy,
        ),
      ],
    ),
  );
}

/// Topology for [turnTestOwNwMinorTribeAttackGame].
MapTopology turnTestOwNwMinorTribeAttackTopology() {
  return MapTopology(
    nodes: const [
      TopologyNode(
        id: 'P1',
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'P2',
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'N1',
        regionId: kRegionNewWorld,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'N2',
        regionId: kRegionNewWorld,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [
      TopologyEdge(id1: 'P1', id2: 'P2'),
      TopologyEdge(id1: 'N1', id2: 'N2'),
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
