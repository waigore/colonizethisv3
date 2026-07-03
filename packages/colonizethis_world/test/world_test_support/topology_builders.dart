import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Canonical old-world region id for world test support builders.
const String kWorldTestOw = 'oldWorld';

/// Canonical new-world region id for world test support builders.
const String kWorldTestNw = 'newWorld';

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

/// Blockade target: [idleProvinceId] unlinked; [seaZoneId] adjacent to [targetProvinceId].
MapTopology blockadeTargetProvinceTopology({
  required String regionId,
  String idleProvinceId = 'p1',
  String targetProvinceId = 'p2',
  String seaZoneId = 'sea1',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: idleProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: targetProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaZoneId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: seaZoneId, id2: targetProvinceId)],
  );
}

/// Two sea zones both adjacent to the same target province.
MapTopology dualSeaZonesTargetProvinceTopology({
  required String regionId,
  String idleProvinceId = 'p1',
  String targetProvinceId = 'p2',
  String sea1Id = 'sea1',
  String sea2Id = 'sea2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: idleProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: targetProvinceId,
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
      TopologyEdge(id1: sea1Id, id2: targetProvinceId),
      TopologyEdge(id1: sea2Id, id2: targetProvinceId),
    ],
  );
}

/// OW sea zone adjacent to NW province (cross-region blockade topology).
MapTopology crossRegionOwSeaToNwProvinceTopology({
  String owProvinceId = 'p1',
  String nwProvinceId = 'n1',
  String owSeaId = 'sea_ow',
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
    ],
    edges: [TopologyEdge(id1: owSeaId, id2: nwProvinceId)],
  );
}

/// NW sea zone adjacent to OW province (cross-region blockade topology).
MapTopology crossRegionNwSeaToOwProvinceTopology({
  String owProvince1Id = 'p1',
  String owProvince2Id = 'p2',
  String nwSeaId = 'sea_nw',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: owProvince1Id,
        regionId: kWorldTestOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: owProvince2Id,
        regionId: kWorldTestOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: nwSeaId,
        regionId: kWorldTestNw,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: nwSeaId, id2: owProvince2Id)],
  );
}

/// OW two provinces + NW province; each sea targets its region's blockade province.
MapTopology dualRegionBlockadeTargetsTopology({
  String owProvince1Id = 'p1',
  String owProvince2Id = 'p2',
  String nwProvinceId = 'n1',
  String owSeaId = 'sea1',
  String nwSeaId = 'sea2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: owProvince1Id,
        regionId: kWorldTestOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: owProvince2Id,
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
      TopologyEdge(id1: owSeaId, id2: owProvince2Id),
      TopologyEdge(id1: nwSeaId, id2: nwProvinceId),
    ],
  );
}

/// Inland province plus seaboard province adjacent to [seaZoneId].
MapTopology inlandAndSeaboardProvincesTopology({
  required String regionId,
  String inlandProvinceId = 'p1',
  String seaboardProvinceId = 'p2',
  String seaZoneId = 'sea1',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: inlandProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaboardProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaZoneId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: seaboardProvinceId, id2: seaZoneId)],
  );
}

/// Two provinces in one region with no sea (connectivity parity tests).
MapTopology twoProvinceLandTopology({
  required String regionId,
  String province1Id = 'p1',
  String province2Id = 'p2',
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
    ],
    edges: const [],
  );
}

/// Empty topology for legacy no-op move paths.
const MapTopology kEmptyMapTopology = MapTopology();

/// Three land provinces with a single [province1Id]–[province2Id] adjacency.
MapTopology threeProvincePartialChainTopology({
  required String regionId,
  String province1Id = 'p1',
  String province2Id = 'p2',
  String province3Id = 'p3',
}) {
  return topologyFromGraph(
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
        id: province3Id,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: province1Id, id2: province2Id)],
  );
}

/// Prefixed-id adjacent provinces ([province1LocalId]–[province2LocalId] linked).
MapTopology prefixedAdjacentProvincesTopology({
  required String regionId,
  String province1LocalId = 'p1',
  String province2LocalId = 'p2',
  String province3LocalId = 'p3',
}) {
  final p1 = '$regionId|$province1LocalId';
  final p2 = '$regionId|$province2LocalId';
  final p3 = '$regionId|$province3LocalId';
  return topologyFromGraph(
    nodes: [
      prefixedProvinceNode(p1),
      prefixedProvinceNode(p2),
      prefixedProvinceNode(p3),
    ],
    edges: [TopologyEdge(id1: p1, id2: p2)],
  );
}

/// OW/NW provinces + seas with cross-region S–S warp (prefixed node ids).
MapTopology prefixedDualRegionNavalWarpTopology({
  String owProvinceLocalId = 'p1',
  String owSeaLocalId = 's1',
  String nwProvinceLocalId = 'n1',
  String nwSeaLocalId = 's2',
}) {
  final owP = '$kWorldTestOw|$owProvinceLocalId';
  final owS = '$kWorldTestOw|$owSeaLocalId';
  final nwP = '$kWorldTestNw|$nwProvinceLocalId';
  final nwS = '$kWorldTestNw|$nwSeaLocalId';
  return topologyFromGraph(
    nodes: [
      prefixedProvinceNode(owP),
      prefixedSeaZoneNode(owS),
      prefixedProvinceNode(nwP),
      prefixedSeaZoneNode(nwS),
    ],
    edges: [
      TopologyEdge(id1: owP, id2: owS),
      TopologyEdge(id1: owS, id2: nwS),
      TopologyEdge(id1: nwP, id2: nwS),
    ],
  );
}

/// Same local province id in two regions with region-scoped sea adjacency.
MapTopology duplicateLocalProvinceIdsByRegionTopology({
  String sharedLocalProvinceId = 'p1',
  String owSeaLocalId = 'sea1',
  String nwSeaLocalId = 'sea2',
}) {
  return topologyFromGraph(
    nodes: [
      TopologyNode(
        id: sharedLocalProvinceId,
        regionId: kWorldTestOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: owSeaLocalId,
        regionId: kWorldTestOw,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: sharedLocalProvinceId,
        regionId: kWorldTestNw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: nwSeaLocalId,
        regionId: kWorldTestNw,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: sharedLocalProvinceId, id2: owSeaLocalId),
      TopologyEdge(id1: sharedLocalProvinceId, id2: nwSeaLocalId),
    ],
  );
}

/// OW two provinces plus NW province (land only, multi-faction non-GP tests).
MapTopology threeProvinceDualRegionLandTopology({
  String owProvince1Id = 'p1',
  String owProvince2Id = 'p2',
  String nwProvinceId = 'p3',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: owProvince1Id,
        regionId: kWorldTestOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: owProvince2Id,
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
