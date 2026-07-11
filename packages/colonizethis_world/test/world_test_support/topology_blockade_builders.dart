import 'package:colonizethis_data/colonizethis_data.dart';

import 'topology_constants.dart';
import 'topology_graph_dsl.dart';

/// Blockade target: [idleProvinceId] unlinked; [seaZoneId] adjacent to [targetProvinceId].
MapTopology blockadeTargetProvinceTopology({
  required String regionId,
  String idleProvinceId = 'p1',
  String targetProvinceId = 'p2',
  String seaZoneId = 'sea1',
}) {
  return topologyGraph(
    regionId: regionId,
    provinces: [idleProvinceId, targetProvinceId],
    seas: [seaZoneId],
    edges: [(seaZoneId, targetProvinceId)],
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
  return topologyGraph(
    regionId: regionId,
    provinces: [idleProvinceId, targetProvinceId],
    seas: [sea1Id, sea2Id],
    edges: [(sea1Id, targetProvinceId), (sea2Id, targetProvinceId)],
  );
}

/// OW sea zone adjacent to NW province (cross-region blockade topology).
MapTopology crossRegionOwSeaToNwProvinceTopology({
  String owProvinceId = 'p1',
  String nwProvinceId = 'n1',
  String owSeaId = 'sea_ow',
}) {
  return topologyGraphNodes(
    nodes: [
      provinceRow(kWorldTestOw, owProvinceId),
      provinceRow(kWorldTestNw, nwProvinceId),
      seaRow(kWorldTestOw, owSeaId),
    ],
    edges: [(owSeaId, nwProvinceId)],
  );
}

/// NW sea zone adjacent to OW province (cross-region blockade topology).
MapTopology crossRegionNwSeaToOwProvinceTopology({
  String owProvince1Id = 'p1',
  String owProvince2Id = 'p2',
  String nwSeaId = 'sea_nw',
}) {
  return topologyGraphNodes(
    nodes: [
      provinceRow(kWorldTestOw, owProvince1Id),
      provinceRow(kWorldTestOw, owProvince2Id),
      seaRow(kWorldTestNw, nwSeaId),
    ],
    edges: [(nwSeaId, owProvince2Id)],
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
  return topologyGraphNodes(
    nodes: [
      provinceRow(kWorldTestOw, owProvince1Id),
      provinceRow(kWorldTestOw, owProvince2Id),
      provinceRow(kWorldTestNw, nwProvinceId),
      seaRow(kWorldTestOw, owSeaId),
      seaRow(kWorldTestNw, nwSeaId),
    ],
    edges: [
      (owSeaId, owProvince2Id),
      (nwSeaId, nwProvinceId),
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
  return topologyGraph(
    regionId: regionId,
    provinces: [inlandProvinceId, seaboardProvinceId],
    seas: [seaZoneId],
    edges: [(seaboardProvinceId, seaZoneId)],
  );
}
