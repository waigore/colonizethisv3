// Warp zone generation. SPEC/game/map-topology.md § Warp zones, game-setup-pipeline.md step 4.
// One warp zone per map edge (sea zone on grid boundary); equal count per map; 1:1 pairing.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';

/// Picks one representative sea zone per map edge (top, bottom, left, right).
/// Returns a map of edge name ('top', 'bottom', 'left', 'right') to sea zone id.
/// Uses deterministic selection based on [seed] for reproducibility.
Map<String, String> seaZonesPerEdge(
  TileMapResult tileMap,
  MapTopology topology,
  int seed,
) {
  final seaZoneIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.seaZone)
      .map((n) => n.id)
      .toSet();
  if (seaZoneIds.isEmpty || tileMap.width == 0 || tileMap.height == 0) {
    return {};
  }

  final rng = Random(seed);
  final result = <String, String>{};
  final w = tileMap.width;
  final h = tileMap.height;

  // Collect sea zones on each edge.
  final topZones = <String>{};
  final bottomZones = <String>{};
  final leftZones = <String>{};
  final rightZones = <String>{};

  for (var x = 0; x < w; x++) {
    final top = tileMap.cell(x, 0);
    final bottom = tileMap.cell(x, h - 1);
    if (seaZoneIds.contains(top)) topZones.add(top);
    if (seaZoneIds.contains(bottom)) bottomZones.add(bottom);
  }
  for (var y = 0; y < h; y++) {
    final left = tileMap.cell(0, y);
    final right = tileMap.cell(w - 1, y);
    if (seaZoneIds.contains(left)) leftZones.add(left);
    if (seaZoneIds.contains(right)) rightZones.add(right);
  }

  // Pick one representative per edge (deterministic random selection).
  if (topZones.isNotEmpty) {
    final list = topZones.toList()..sort();
    result['top'] = list[rng.nextInt(list.length)];
  }
  if (bottomZones.isNotEmpty) {
    final list = bottomZones.toList()..sort();
    result['bottom'] = list[rng.nextInt(list.length)];
  }
  if (leftZones.isNotEmpty) {
    final list = leftZones.toList()..sort();
    result['left'] = list[rng.nextInt(list.length)];
  }
  if (rightZones.isNotEmpty) {
    final list = rightZones.toList()..sort();
    result['right'] = list[rng.nextInt(list.length)];
  }

  return result;
}

/// Generates warp links between OW and NW. Aims for one warp zone per map edge;
/// pairs edges between the two maps deterministically based on [seed].
/// Maximum 4 warp links (one per edge: top, bottom, left, right).
List<WarpLink> generateWarpZones({
  required TileMapResult tileMapOldWorld,
  required MapTopology topologyOldWorld,
  required TileMapResult tileMapNewWorld,
  required MapTopology topologyNewWorld,
  required String regionIdOld,
  required String regionIdNew,
  int seed = 42,
}) {
  final owZones = seaZonesPerEdge(tileMapOldWorld, topologyOldWorld, seed);
  final nwZones = seaZonesPerEdge(tileMapNewWorld, topologyNewWorld, seed + 1);

  // Find common edges that have sea zones on both maps.
  final commonEdges = owZones.keys.where((e) => nwZones.containsKey(e)).toList()
    ..sort();

  if (commonEdges.isEmpty) {
    logicLog.d('warp zones: no common edges with sea zones, skipping');
    return [];
  }

  final links = <WarpLink>[];
  for (final edge in commonEdges) {
    links.add(
      WarpLink(
        regionId: regionIdOld,
        seaZoneId: owZones[edge]!,
        otherRegionId: regionIdNew,
        otherSeaZoneId: nwZones[edge]!,
      ),
    );
  }

  logicLog.d(
    'warp zones: ${links.length} links on edges ${commonEdges.join(", ")}',
  );
  return links;
}
