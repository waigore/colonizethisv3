import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared fixtures for [army_move_picker_destinations] tests (Refs #2394).
const ow = 'oldWorld';
const nw = 'newWorld';

Army fieldArmy(String regionId, String ownerId, String localId, String unitId) {
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

final adjacencyOw = MapTopology(
  nodes: const [
    TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
    TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
  ],
  edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
);

Map<String, String> vis(List<(String, String)> tiles) {
  return {for (final (_, tk) in tiles) tk: 'fullyVisible'};
}
