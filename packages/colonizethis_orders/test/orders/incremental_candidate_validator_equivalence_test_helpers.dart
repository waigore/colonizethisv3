import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

bool fullPassMoveAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  MoveOrder candidate,
) {
  final engine = OrderEngine(initialOrders: basePrefix);
  return engine
      .addMoveOrderWithContext(game, topology, playerId, candidate)
      .isAccepted;
}

bool fullPassArmyMoveAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  ArmyMoveOrder candidate,
) {
  final merged = applyArmyMoveOrderForPlayer(basePrefix, playerId, candidate);
  final engine = OrderEngine(initialOrders: merged);
  final results = engine.validatePlayerOrdersWithContext(
    game,
    topology,
    playerId,
  );
  if (results.isEmpty) return false;
  return results.every((r) => r.isAccepted);
}

bool fullPassBuildAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  BuildUnitOrder candidate,
) {
  final engine = OrderEngine(initialOrders: basePrefix);
  return engine
      .addBuildOrderWithContext(game, topology, playerId, candidate)
      .isAccepted;
}

bool fullPassWorkAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  WorkOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final engine = OrderEngine(initialOrders: basePrefix);
  return engine
      .addWorkOrderWithContext(
        game,
        topology,
        playerId,
        candidate,
        tileMapByRegion: tileMapByRegion,
      )
      .isAccepted;
}

bool fullPassDiplomaticAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  DiplomaticOrder candidate,
) {
  final engine = OrderEngine(initialOrders: basePrefix);
  return engine
      .addDiplomaticOrderWithContext(game, topology, playerId, candidate)
      .isAccepted;
}

void expectMoveEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required MoveOrder candidate,
  required String label,
}) {
  final fullPass = fullPassMoveAccepted(
    game,
    topology,
    playerId,
    basePrefix,
    candidate,
  );
  final incremental = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
  ).isMoveAccepted(candidate);
  expect(
    incremental,
    equals(fullPass),
    reason:
        'Move candidate "$label" diverged: incremental=$incremental, fullPass=$fullPass',
  );
}

void expectArmyMoveEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required ArmyMoveOrder candidate,
  required String label,
}) {
  final fullPass = fullPassArmyMoveAccepted(
    game,
    topology,
    playerId,
    basePrefix,
    candidate,
  );
  final incremental = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
  ).isArmyMoveAccepted(candidate);
  expect(
    incremental,
    equals(fullPass),
    reason:
        'Army move candidate "$label" diverged: incremental=$incremental, fullPass=$fullPass',
  );
}

void expectBuildEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required BuildUnitOrder candidate,
  required String label,
}) {
  final fullPass = fullPassBuildAccepted(
    game,
    topology,
    playerId,
    basePrefix,
    candidate,
  );
  final incremental = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
  ).isBuildAccepted(candidate);
  expect(
    incremental,
    equals(fullPass),
    reason:
        'Build candidate "$label" diverged: incremental=$incremental, fullPass=$fullPass',
  );
}

void expectWorkEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required WorkOrder candidate,
  required String label,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final fullPass = fullPassWorkAccepted(
    game,
    topology,
    playerId,
    basePrefix,
    candidate,
    tileMapByRegion: tileMapByRegion,
  );
  final incremental = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    tileMapByRegion: tileMapByRegion,
  ).isWorkAccepted(candidate);
  expect(
    incremental,
    equals(fullPass),
    reason:
        'Work candidate "$label" diverged: incremental=$incremental, fullPass=$fullPass',
  );
}

void expectDiplomaticEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required DiplomaticOrder candidate,
  required String label,
}) {
  final fullPass = fullPassDiplomaticAccepted(
    game,
    topology,
    playerId,
    basePrefix,
    candidate,
  );
  final incremental = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
  ).isDiplomaticAccepted(candidate);
  expect(
    incremental,
    equals(fullPass),
    reason:
        'Diplomatic candidate "$label" diverged: incremental=$incremental, fullPass=$fullPass',
  );
}

Game moveCorpusGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g_move_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
          Province(id: '$ow|P4', regionId: ow, ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
            tileKey: '$ow|P1|0|0',
          ),
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
            tileKey: '$ow|P1|0|0',
          ),
          Unit(
            id: 'u_spy',
            type: kUnitTypeSpy,
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
            tileKey: '$ow|P1|0|0',
          ),
          Unit(
            id: 'u_pikemen',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|P1': ['$ow|P1|0|0'],
          '$ow|P2': ['$ow|P2|0|0'],
          '$ow|P3': ['$ow|P3|0|0'],
          '$ow|P4': ['$ow|P4|0|0'],
        },
      },
      playerVisibilityByTile: const {
        'p1': {
          '$ow|P1|0|0': 'fullyVisible',
          '$ow|P2|0|0': 'fogged',
          '$ow|P3|0|0': 'fogged',
          '$ow|P4|0|0': 'fogged',
        },
      },
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
  );
}

MapTopology moveCorpusTopology() {
  const ow = 'oldWorld';
  return MapTopology(
    nodes: const [
      TopologyNode(id: '$ow|P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P2', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P3', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P4', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [],
  );
}

Game armyCorpusGame() {
  const ow = 'oldWorld';
  Army field(String id, String stationed, String regimentId) => Army(
    id: id,
    ownerId: 'p1',
    regionId: ow,
    stationedProvinceId: stationed,
    regimentUnitIds: [regimentId],
    isHomeArmy: false,
  );
  return Game(
    id: 'g_army_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
          Province(id: '$ow|P4', regionId: ow, ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'r1',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [field('field_a', '$ow|P1', 'r1')],
      playerVisibilityByTile: const {
        'p1': {
          '$ow|P1|0|0': 'fullyVisible',
          '$ow|P2|0|0': 'fogged',
          '$ow|P3|0|0': 'fogged',
          '$ow|P4|0|0': 'fogged',
        },
      },
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|P1': ['$ow|P1|0|0'],
          '$ow|P2': ['$ow|P2|0|0'],
          '$ow|P3': ['$ow|P3|0|0'],
          '$ow|P4': ['$ow|P4|0|0'],
        },
      },
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
    diplomacyRelations: const [],
  );
}

MapTopology armyCorpusTopology() {
  const ow = 'oldWorld';
  return MapTopology(
    nodes: const [
      TopologyNode(id: '$ow|P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P2', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P3', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P4', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [
      TopologyEdge(id1: '$ow|P1', id2: '$ow|P2'),
      TopologyEdge(id1: '$ow|P1', id2: '$ow|P3'),
      TopologyEdge(id1: '$ow|P1', id2: '$ow|P4'),
    ],
  );
}
