import 'package:colonizethis_data/colonizethis_data.dart';

import 'topology_constants.dart';
import 'topology_core_builders.dart';
import 'topology_graph_dsl.dart';

/// Two provinces in one region with no sea (connectivity parity tests).
MapTopology twoProvinceLandTopology({
  required String regionId,
  String province1Id = 'p1',
  String province2Id = 'p2',
}) {
  return topologyGraph(
    regionId: regionId,
    provinces: [province1Id, province2Id],
  );
}

/// Three land provinces with a single [province1Id]–[province2Id] adjacency.
MapTopology threeProvincePartialChainTopology({
  required String regionId,
  String province1Id = 'p1',
  String province2Id = 'p2',
  String province3Id = 'p3',
}) {
  return topologyGraph(
    regionId: regionId,
    provinces: [province1Id, province2Id, province3Id],
    edges: [(province1Id, province2Id)],
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
  return topologyGraphNodes(
    nodes: [
      provinceRow(kWorldTestOw, sharedLocalProvinceId),
      seaRow(kWorldTestOw, owSeaLocalId),
      provinceRow(kWorldTestNw, sharedLocalProvinceId),
      seaRow(kWorldTestNw, nwSeaLocalId),
    ],
    edges: [
      (sharedLocalProvinceId, owSeaLocalId),
      (sharedLocalProvinceId, nwSeaLocalId),
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
  return topologyGraphNodes(
    nodes: [
      provinceRow(kWorldTestOw, owCoastProv),
      seaRow(kWorldTestOw, seaOrigin),
      seaRow(kWorldTestOw, seaDest),
      provinceRow(kWorldTestNw, nwProvince),
      seaRow(kWorldTestNw, nwSea),
    ],
    edges: [
      (owCoastProv, seaDest),
      (seaOrigin, seaDest),
      (nwProvince, nwSea),
    ],
  );
}

/// OW two provinces plus NW province (land only, multi-faction non-GP tests).
MapTopology threeProvinceDualRegionLandTopology({
  String owProvince1Id = 'p1',
  String owProvince2Id = 'p2',
  String nwProvinceId = 'p3',
}) {
  return topologyGraphNodes(
    nodes: [
      provinceRow(kWorldTestOw, owProvince1Id),
      provinceRow(kWorldTestOw, owProvince2Id),
      provinceRow(kWorldTestNw, nwProvinceId),
    ],
  );
}
