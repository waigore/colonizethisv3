import 'package:colonizethis_data/colonizethis_data.dart';

import 'topology_constants.dart';

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
