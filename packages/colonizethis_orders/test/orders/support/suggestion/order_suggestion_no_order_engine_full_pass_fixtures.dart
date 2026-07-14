// Shared no-OrderEngine-full-pass scenario fixtures (Refs #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const _playerId = 'gp1';
const _ow = 'oldWorld';

({Game game, MapTopology topology, PlayerView view})
noefpBuildSuggestionGame() {
  final game = ordersOwRegionGame(
    id: 'g1',
    turnNumber: 1,
    players: [
      Player(
        id: _playerId,
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: '$_ow|p1',
        workerPool: const WorkerPool(peasants: 2),
        treasury: 500,
      ),
    ],
    oldWorld: RegionData(
      provinces: [Province(id: '$_ow|p1', regionId: _ow, ownerId: _playerId)],
    ),
  );
  final topology = ordersProvinceTopology(
    game.worldState.oldWorld.provinces,
    regionId: _ow,
  );
  return (
    game: game,
    topology: topology,
    view: buildPlayerView(game, topology, _playerId),
  );
}

({Game game, MapTopology topology}) noefpAddWithContextGame() {
  final game = ordersOwRegionGame(
    id: 'g1',
    turnNumber: 0,
    players: const [Player(id: _playerId, displayName: 'P1', isHuman: true)],
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
    playerVisibilityByTile: const {
      _playerId: {
        'oldWorld|P1|0|0': 'fullyVisible',
        'oldWorld|P2|0|0': 'fullyVisible',
      },
    },
  );
  return (
    game: game,
    topology: ordersProvinceTopology(
      game.worldState.oldWorld.provinces,
      regionId: _ow,
      edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
    ),
  );
}
