import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Canonical old-world region id for world test support builders.
const String kWorldTestOw = 'oldWorld';

/// Canonical new-world region id for world test support builders.
const String kWorldTestNw = 'newWorld';

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
