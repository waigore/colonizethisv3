import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Old World region id for two-province integration setups in turn tests.
const turnTestOldWorldRegionId = kRegionOldWorld;

/// 1×1 tile key in Old World for [localProvinceId] (e.g. `P2` → `oldWorld|P2|0|0`).
String turnTestOwTileKey(String localProvinceId) =>
    '${turnTestOldWorldRegionId}|$localProvinceId|0|0';

/// 1×1 tile key in New World for [localProvinceId].
String turnTestNwTileKey(String localProvinceId) =>
    '${kRegionNewWorld}|$localProvinceId|0|0';

/// Two Old World provinces; when [adjacent] is true they share a topology edge.
MapTopology twoAdjacentOldWorldProvinceTopology({
  String id1 = 'P1',
  String id2 = 'P2',
  String regionId = turnTestOldWorldRegionId,
  bool adjacent = true,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: id1,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: id2,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: adjacent
        ? [TopologyEdge(id1: id1, id2: id2)]
        : const <TopologyEdge>[],
  );
}

/// Prefixed Old World province id for [adjacentOwP1P2Game] setups (`oldWorld|P1`).
String turnTestOwProvinceId(String localId) =>
    '$turnTestOldWorldRegionId|$localId';

/// Single OW province topology (no sea).
MapTopology turnTestOwSingleProvinceTopology({String provinceLocalId = 'P1'}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: provinceLocalId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
}

/// Two-province OW + NW cross-region topology (no edges).
MapTopology turnTestOwNwCrossRegionTopology({
  String owProvinceLocalId = 'P1',
  String nwProvinceLocalId = 'P2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: owProvinceLocalId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: nwProvinceLocalId,
        regionId: kRegionNewWorld,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
}

/// Two adjacent OW provinces owned by [owner1Id] / [owner2Id].
List<Province> turnTestOwP1P2Provinces({
  String owner1Id = 'p1',
  String owner2Id = 'p2',
}) {
  return [
    Province(
      id: turnTestOwProvinceId('P1'),
      regionId: kRegionOldWorld,
      ownerId: owner1Id,
    ),
    Province(
      id: turnTestOwProvinceId('P2'),
      regionId: kRegionOldWorld,
      ownerId: owner2Id,
    ),
  ];
}
