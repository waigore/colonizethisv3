// Shared no-OrderEngine-full-pass scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const _playerId = 'gp1';
const _ow = 'oldWorld';

({Game game, MapTopology topology, PlayerView view}) noefpBuildSuggestionGame() {
  final player = Player(
    id: _playerId,
    displayName: 'GP',
    isHuman: false,
    capitalProvinceId: '$_ow|p1',
    workerPool: const WorkerPool(peasants: 2),
    treasury: 500,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [Province(id: '$_ow|p1', regionId: _ow, ownerId: _playerId)],
      units: const [],
    ),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [],
  );
  return (
    game: game,
    topology: topology,
    view: buildPlayerView(game, topology, _playerId),
  );
}

({Game game, MapTopology topology}) noefpAddWithContextGame() {
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$_ow|P1', regionId: _ow, ownerId: _playerId),
          Province(id: '$_ow|P2', regionId: _ow, ownerId: _playerId),
        ],
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeBuilder,
            ownerId: _playerId,
            locationProvinceId: '$_ow|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: const {
        _playerId: {
          'oldWorld|P1|0|0': 'fullyVisible',
          'oldWorld|P2|0|0': 'fullyVisible',
        },
      },
    ),
    players: const [Player(id: _playerId, displayName: 'P1', isHuman: true)],
  );
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: 'P1',
        regionId: _ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'P2',
        regionId: _ow,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
  );
  return (game: game, topology: topology);
}
