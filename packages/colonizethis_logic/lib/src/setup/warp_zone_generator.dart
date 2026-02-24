// Warp zone generation. SPEC/game/map-topology.md § Warp zones, game-setup-pipeline.md step 4.
// One warp zone per map edge (sea zone on grid boundary); equal count per map; 1:1 pairing.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:logger/logger.dart';

final Logger _log = Logger();

/// Returns sea zone ids that have at least one tile on the grid boundary (edge) of [tileMap].
/// Used to pick warp zones per spec: one per map edge, using a sea zone on the edge.
Set<String> seaZonesOnEdge(TileMapResult tileMap, MapTopology topology) {
  final seaZoneIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.seaZone)
      .map((n) => n.id)
      .toSet();
  if (seaZoneIds.isEmpty || tileMap.width == 0 || tileMap.height == 0) {
    return {};
  }
  final onEdge = <String>{};
  final w = tileMap.width;
  final h = tileMap.height;
  for (var x = 0; x < w; x++) {
    final top = tileMap.cell(x, 0);
    final bottom = tileMap.cell(x, h - 1);
    if (seaZoneIds.contains(top)) onEdge.add(top);
    if (seaZoneIds.contains(bottom)) onEdge.add(bottom);
  }
  for (var y = 0; y < h; y++) {
    final left = tileMap.cell(0, y);
    final right = tileMap.cell(w - 1, y);
    if (seaZoneIds.contains(left)) onEdge.add(left);
    if (seaZoneIds.contains(right)) onEdge.add(right);
  }
  return onEdge;
}

/// Generates warp links between OW and NW. Aims for one warp zone per map edge (sea zone on edge);
/// if not possible, the number of warp zones on each map is still equal (each links to exactly one on the other map).
/// Deterministic for given [seed].
List<WarpLink> generateWarpZones({
  required TileMapResult tileMapOldWorld,
  required MapTopology topologyOldWorld,
  required TileMapResult tileMapNewWorld,
  required MapTopology topologyNewWorld,
  required String regionIdOld,
  required String regionIdNew,
  int seed = 42,
}) {
  final owEdge = seaZonesOnEdge(tileMapOldWorld, topologyOldWorld);
  final nwEdge = seaZonesOnEdge(tileMapNewWorld, topologyNewWorld);
  if (owEdge.isEmpty || nwEdge.isEmpty) {
    _log.d('logic: warp zones: no edge sea zones (OW=${owEdge.length}, NW=${nwEdge.length}), skipping');
    return [];
  }
  final owList = owEdge.toList()..sort();
  final nwList = nwEdge.toList()..sort();
  final n = owList.length < nwList.length ? owList.length : nwList.length;
  if (n == 0) return [];
  final links = <WarpLink>[];
  for (var i = 0; i < n; i++) {
    links.add(WarpLink(
      regionId: regionIdOld,
      seaZoneId: owList[i],
      otherRegionId: regionIdNew,
      otherSeaZoneId: nwList[i],
    ));
  }
  _log.d('logic: warp zones: ${links.length} links (OW edge=${owList.length}, NW edge=${nwList.length})');
  return links;
}
