import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'topology_constants.dart';

/// Province topology node with a prefixed id (`regionId|localId`).
TopologyNode prefixedProvinceNode(String prefixedId) => TopologyNode(
  id: prefixedId,
  regionId: ProvinceId.regionIdFrom(prefixedId),
  type: TopologyNodeType.province,
);

/// Sea-zone topology node with a prefixed id (`regionId|localId`).
TopologyNode prefixedSeaZoneNode(String prefixedId) => TopologyNode(
  id: prefixedId,
  regionId: ProvinceId.regionIdFrom(prefixedId),
  type: TopologyNodeType.seaZone,
);

/// Explicit node/edge list for tests that need prefixed province ids.
MapTopology topologyFromGraph({
  required List<TopologyNode> nodes,
  List<TopologyEdge> edges = const [],
}) {
  return MapTopology(nodes: nodes, edges: edges);
}

/// Single province adjacent to a sea zone in [regionId].
MapTopology provinceSeaZoneTopology({
  required String regionId,
  required String provinceLocalId,
  required String seaZoneId,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: provinceLocalId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaZoneId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: seaZoneId, id2: provinceLocalId)],
  );
}

/// OW/NW provinces linked via sea zones (common blockade/connectivity setup).
MapTopology dualRegionLinkedSeaTopology({
  String owProvinceId = 'p1',
  String nwProvinceId = 'p2',
  String owSeaId = 'sea1',
  String nwSeaId = 'sea2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: owProvinceId,
        regionId: kWorldTestOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: nwProvinceId,
        regionId: kWorldTestNw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: owSeaId,
        regionId: kWorldTestOw,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: nwSeaId,
        regionId: kWorldTestNw,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: owProvinceId, id2: owSeaId),
      TopologyEdge(id1: nwProvinceId, id2: nwSeaId),
      TopologyEdge(id1: owSeaId, id2: nwSeaId),
    ],
  );
}

/// Uniform [size]×[size] tile grid filled with [provinceLocalId].
TileMapResult uniformProvinceTileMap(
  String provinceLocalId, {
  int size = 2,
}) {
  final grid = List.generate(
    size,
    (_) => List.filled(size, provinceLocalId),
  );
  return TileMapResult(width: size, height: size, grid: grid);
}

/// Dual-region tile maps for connectivity tests (default 2×2 per region).
Map<String, TileMapResult> dualRegionUniformTileMaps({
  String owProvinceId = 'p1',
  String nwProvinceId = 'p2',
  int size = 2,
}) {
  return {
    kWorldTestOw: uniformProvinceTileMap(owProvinceId, size: size),
    kWorldTestNw: uniformProvinceTileMap(nwProvinceId, size: size),
  };
}

/// [grid] must be rectangular; width/height derived from first row/column count.
TileMapResult tileMapFromGrid(List<List<String>> grid) {
  return TileMapResult(
    width: grid.first.length,
    height: grid.length,
    grid: grid,
  );
}

/// Single province with no adjacency edges.
MapTopology singleProvinceTopology({
  required String regionId,
  required String provinceLocalId,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: provinceLocalId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
}

/// Two provinces each adjacent to their own sea zone (no cross-province links).
MapTopology dualProvinceDualSeaTopology({
  required String regionId,
  String province1Id = 'p1',
  String province2Id = 'p2',
  String sea1Id = 's1',
  String sea2Id = 's2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: province1Id,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: province2Id,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: sea1Id,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: sea2Id,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: province1Id, id2: sea1Id),
      TopologyEdge(id1: province2Id, id2: sea2Id),
    ],
  );
}

/// Province adjacent to near sea; near sea linked to distant sea (p1–s1–s2).
MapTopology provinceSeaChainTopology({
  required String regionId,
  String provinceLocalId = 'p1',
  String nearSeaId = 's1',
  String distantSeaId = 's2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: provinceLocalId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: nearSeaId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: distantSeaId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: provinceLocalId, id2: nearSeaId),
      TopologyEdge(id1: nearSeaId, id2: distantSeaId),
    ],
  );
}

/// Province and sea zone nodes with no edge (intentionally unlinked).
MapTopology provinceAndSeaUnlinkedTopology({
  required String regionId,
  String provinceLocalId = 'p1',
  String seaZoneId = 's1',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: provinceLocalId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaZoneId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [],
  );
}

/// Isolated sea zone (no province adjacency).
MapTopology isolatedSeaZoneTopology({
  required String regionId,
  required String seaZoneId,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: seaZoneId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [],
  );
}

/// OW single province plus NW single province (land only, no sea).
MapTopology dualRegionLandOnlyTopology({
  String owProvinceId = 'p1',
  String nwProvinceId = 'P2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: owProvinceId,
        regionId: kWorldTestOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: nwProvinceId,
        regionId: kWorldTestNw,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
}

/// Merge node/edge lists from multiple topologies into one graph.
MapTopology mergeTopologies(List<MapTopology> parts) {
  return MapTopology(
    nodes: [for (final part in parts) ...part.nodes],
    edges: [for (final part in parts) ...part.edges],
  );
}

/// OW province–sea chain plus isolated NW sea (GitHub #2023 fog revert tests).
({
  MapTopology combined,
  MapTopology ow,
  MapTopology nw,
}) owSeaChainWithIsolatedNwSea({
  String owProvinceId = 'p1',
  String owNearSeaId = 's1',
  String owDistantSeaId = 's2',
  String nwSeaId = 'nwSea',
}) {
  final ow = provinceSeaChainTopology(
    regionId: kWorldTestOw,
    provinceLocalId: owProvinceId,
    nearSeaId: owNearSeaId,
    distantSeaId: owDistantSeaId,
  );
  final nw = isolatedSeaZoneTopology(
    regionId: kWorldTestNw,
    seaZoneId: nwSeaId,
  );
  return (combined: mergeTopologies([ow, nw]), ow: ow, nw: nw);
}
