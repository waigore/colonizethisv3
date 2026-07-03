import 'package:colonizethis_data/colonizethis_data.dart';

import 'topology_constants.dart';
import 'topology_core_builders.dart';

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

/// Combined OW/NW topology for home-fleet split + movement integration (#2010).
MapTopology homeFleetSplitMovementIntegrationTopology({
  String owCoastProv = 'oldWorld|pCoast',
  String seaOrigin = 'oldWorld|seaOrigin',
  String seaDest = 'oldWorld|seaDest',
  String nwProvince = 'newWorld|p1',
  String nwSea = 'newWorld|seaOther',
}) {
  return topologyFromGraph(
    nodes: [
      TopologyNode(
        id: owCoastProv,
        regionId: kWorldTestOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaOrigin,
        regionId: kWorldTestOw,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: seaDest,
        regionId: kWorldTestOw,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: nwProvince,
        regionId: kWorldTestNw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: nwSea,
        regionId: kWorldTestNw,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: owCoastProv, id2: seaDest),
      TopologyEdge(id1: seaOrigin, id2: seaDest),
      TopologyEdge(id1: nwProvince, id2: nwSea),
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
