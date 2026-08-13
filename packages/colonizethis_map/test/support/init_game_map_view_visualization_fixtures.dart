import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'init_game_map_view_fixtures.dart';

/// Visualization render topology/tile helpers (Refs #4371 densify).

MapTopology oldWorldTwoProvinceSeaVisualizationTopology() {
  return regionTopology(
    regionId: 'oldWorld',
    provinceIds: const ['p1', 'p2'],
    seaZoneIds: const ['s1'],
    edges: const [
      TopologyEdge(id1: 'p1', id2: 'p2'),
      TopologyEdge(id1: 'p1', id2: 's1'),
    ],
  );
}

/// Two adjacent sea zones in [regionId] (sea–sea border render tests).
MapTopology twoAdjacentSeaZonesTopology(String regionId) {
  return regionTopology(
    regionId: regionId,
    seaZoneIds: const ['s1', 's2'],
    edges: const [TopologyEdge(id1: 's1', id2: 's2')],
  );
}

/// Standard 4×3 visualization grid with p1/p2 land and s1 sea.
TileMapResult visualizationSmallTileMap() {
  return mapTileGrid([
    ['p1', 'p1', 'p2', 'p2'],
    ['p1', 's1', 's1', 'p2'],
    ['p1', 'p1', 'p2', 'p2'],
  ]);
}
