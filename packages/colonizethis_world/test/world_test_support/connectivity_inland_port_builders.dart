import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'connectivity_builders.dart';
import 'topology_builders.dart';

/// Inland OW capital with a land-connected port province (no shared sea link).
({Game game, MapTopology topology, Map<String, TileMapResult> tileMapByRegion})
inlandCapitalLandPortConnectivityScenario({
  String playerId = 'pl1',
  String owCapitalProvinceId = 'p1',
  String owPortProvinceId = 'p2',
}) {
  const ow = kWorldTestOw;
  final topology = topologyFromGraph(
    nodes: [
      TopologyNode(
        id: owCapitalProvinceId,
        regionId: ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: owPortProvinceId,
        regionId: ow,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final grid = [
    [owCapitalProvinceId, owPortProvinceId],
    [owCapitalProvinceId, owPortProvinceId],
  ];
  final cap = CapitalTile(
    regionId: ow,
    provinceId: '$ow|$owCapitalProvinceId',
    x: 0,
    y: 0,
  );
  final tileState = TileMapState()
      .setRoadLevel('$ow|$owCapitalProvinceId|0|0', 1)
      .setRoadLevel('$ow|$owCapitalProvinceId|1|0', 1)
      .setRoadLevel('$ow|$owPortProvinceId|1|0', 4)
      .setRoadLevel('$ow|$owPortProvinceId|1|1', 4);
  final game = ordersPhaseGame(
    oldWorldProvinces: [
      Province(id: '$ow|$owCapitalProvinceId', regionId: ow, ownerId: playerId),
      Province(id: '$ow|$owPortProvinceId', regionId: ow, ownerId: playerId),
    ],
    tileState: tileState,
    portsByProvinceSeaboard: {
      '$ow|$owPortProvinceId|dummy': '$ow|$owPortProvinceId|1|0',
    },
    players: [
      Player(
        id: playerId,
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|$owCapitalProvinceId',
        capitalTile: cap,
      ),
    ],
  );
  return (
    game: game,
    topology: topology,
    tileMapByRegion: {ow: tileMapFromGrid(grid)},
  );
}
