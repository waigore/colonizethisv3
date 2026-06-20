import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

bool fullPassNavalMoveAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  NavalMoveOrder candidate,
) {
  final engine = OrderEngine(initialOrders: basePrefix);
  return engine
      .addNavalMoveOrderWithContext(game, topology, playerId, candidate)
      .isAccepted;
}

bool fullPassNavalMissionAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  NavalMissionOrder candidate,
) {
  final engine = OrderEngine(initialOrders: basePrefix);
  return engine
      .addNavalMissionOrderWithContext(game, topology, playerId, candidate)
      .isAccepted;
}

void expectNavalMoveEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required NavalMoveOrder candidate,
  required String label,
}) {
  final fullPass = fullPassNavalMoveAccepted(
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
  ).isNavalMoveAccepted(candidate);
  expect(
    incremental,
    equals(fullPass),
    reason:
        'Naval move candidate "$label" diverged: incremental=$incremental, fullPass=$fullPass',
  );
}

void expectNavalMissionEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required NavalMissionOrder candidate,
  required String label,
}) {
  final fullPass = fullPassNavalMissionAccepted(
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
  ).isNavalMissionAccepted(candidate);
  expect(
    incremental,
    equals(fullPass),
    reason:
        'Naval mission candidate "$label" diverged: incremental=$incremental, fullPass=$fullPass',
  );
}

Game navalCorpusGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g_naval_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|coastA', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|coastB', regionId: ow, ownerId: 'p1'),
        ],
      ),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'fleet_atSea',
          ownerId: 'p1',
          regionId: ow,
          seaZoneId: '$ow|sea1',
          shipTypeIds: const ['carrack'],
        ),
        Fleet(
          id: 'fleet_inPort',
          ownerId: 'p1',
          regionId: ow,
          inPortAtProvinceId: '$ow|coastA',
          shipTypeIds: const ['carrack'],
        ),
      ],
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|coastA': ['$ow|coastA|0|0'],
          '$ow|coastB': ['$ow|coastB|0|0'],
        },
      },
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
}

MapTopology navalCorpusTopology() {
  const ow = 'oldWorld';
  return MapTopology(
    nodes: const [
      TopologyNode(
        id: '$ow|coastA',
        regionId: ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: '$ow|coastB',
        regionId: ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: '$ow|sea1',
        regionId: ow,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: '$ow|sea2',
        regionId: ow,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [
      TopologyEdge(id1: '$ow|sea1', id2: '$ow|sea2'),
      TopologyEdge(id1: '$ow|sea1', id2: '$ow|coastA'),
      TopologyEdge(id1: '$ow|sea2', id2: '$ow|coastB'),
    ],
  );
}
