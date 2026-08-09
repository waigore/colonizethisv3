/// Shared Game / topology scaffolds for `generateOrdersWithSimpleHeuristics`
/// and `turnSeedForPlayer` pins (Refs #4084).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Default acting GP for simple-heuristic fixtures.
const String simpleAiPlayerId = 'gp1';

/// Peer GP / faction id used by diplomacy filter pins.
const String simpleAiPeerId = 'gp2';

/// Old-World region id used by most simple-heuristic fixtures.
const String simpleAiOw = 'oldWorld';

/// Empty world shell for seed / missing-player pins.
Game simpleAiEmptyWorldGame({
  List<Player> players = const [
    Player(id: simpleAiPlayerId, displayName: 'GP1', isHuman: false),
  ],
  int turnNumber = 1,
  int globalGameSeed = 0,
  Map<String, int> aiSeedByGpId = const {},
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    globalGameSeed: globalGameSeed,
    aiSeedByGpId: aiSeedByGpId,
  );
}

/// Single-province OW (or NW) topology with no edges.
MapTopology simpleAiSingleProvinceTopology({
  String localId = 'P1',
  String regionId = simpleAiOw,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: localId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
}

/// Two-province adjacent topology (default OW P1–P2).
MapTopology simpleAiAdjacentTopology({
  String a = 'P1',
  String b = 'P2',
  String regionId = simpleAiOw,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(id: a, regionId: regionId, type: TopologyNodeType.province),
      TopologyNode(id: b, regionId: regionId, type: TopologyNodeType.province),
    ],
    edges: [TopologyEdge(id1: a, id2: b)],
  );
}

/// OW military Game: GP owns [homeLocal], optional peer province, one
/// grenadier on home, full visibility on listed locals.
Game simpleAiMilitaryOwGame({
  String homeLocal = 'P1',
  String? peerLocal,
  String peerOwnerId = simpleAiPeerId,
  List<Player> players = const [
    Player(id: simpleAiPlayerId, displayName: 'AI', isHuman: false),
    Player(id: simpleAiPeerId, displayName: 'Other', isHuman: true),
  ],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<MinorNation> minorNations = const [],
  int aiSeed = 42,

  /// When true, store province ids as local-only (P1) instead of prefixed.
  bool localProvinceIds = false,
}) {
  String provinceId(String local) =>
      localProvinceIds ? local : '$simpleAiOw|$local';

  final provinces = <Province>[
    Province(
      id: provinceId(homeLocal),
      regionId: simpleAiOw,
      ownerId: simpleAiPlayerId,
    ),
    if (peerLocal != null)
      Province(
        id: provinceId(peerLocal),
        regionId: simpleAiOw,
        ownerId: peerOwnerId,
      ),
  ];
  final visibilityLocals = <String>[
    homeLocal,
    if (peerLocal != null) peerLocal,
  ];
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: provinces,
        units: [
          Unit(
            id: 'u1',
            type: 'grenadiers',
            ownerId: simpleAiPlayerId,
            locationProvinceId: '$simpleAiOw|$homeLocal',
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: {
        simpleAiPlayerId: {
          for (final local in visibilityLocals)
            '$simpleAiOw|$local|0|0': 'fullyVisible',
        },
      },
    ),
    players: players,
    diplomacyRelations: diplomacyRelations,
    minorNations: minorNations,
    globalGameSeed: 0,
    aiSeedByGpId: {simpleAiPlayerId: aiSeed},
  );
}

/// Single owned OW province Game with optional capital / stockpile / workers.
Game simpleAiSingleOwProvinceGame({
  String localId = 'P1',
  List<Unit> units = const [],
  Map<String, String>? visibility,
  Map<String, List<String>> tileKeysByProvince = const {},
  Player? player,
  int aiSeed = 1,
  int turnNumber = 1,
}) {
  final provinceId = '$simpleAiOw|$localId';
  final resolvedPlayer =
      player ??
      const Player(id: simpleAiPlayerId, displayName: 'AI', isHuman: false);
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: simpleAiOw,
            ownerId: simpleAiPlayerId,
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: {
        simpleAiPlayerId:
            visibility ?? {'$simpleAiOw|$localId|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: tileKeysByProvince.isEmpty
          ? const {}
          : {simpleAiOw: tileKeysByProvince},
    ),
    players: [resolvedPlayer],
    globalGameSeed: 0,
    aiSeedByGpId: {simpleAiPlayerId: aiSeed},
  );
}
