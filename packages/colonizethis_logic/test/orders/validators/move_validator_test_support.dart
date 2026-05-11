import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared topology and army helpers for [MoveValidator] / [ArmyMoveValidator] tests.
MapTopology moveValidatorTestTwoProvinceTopology(String regionId) {
  return MapTopology(
    nodes: [
      TopologyNode(id: 'P1', regionId: regionId, type: TopologyNodeType.province),
      TopologyNode(id: 'P2', regionId: regionId, type: TopologyNodeType.province),
    ],
    edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
  );
}

Army moveValidatorTestFieldArmy(
  String regionId,
  String ownerId,
  String localId,
  String unitId,
) {
  final pid = ProvinceId.full(regionId, localId);
  return Army(
    id: fieldArmyIdFor(ownerId, pid),
    ownerId: ownerId,
    regionId: regionId,
    stationedProvinceId: pid,
    regimentUnitIds: [unitId],
    isHomeArmy: false,
  );
}
