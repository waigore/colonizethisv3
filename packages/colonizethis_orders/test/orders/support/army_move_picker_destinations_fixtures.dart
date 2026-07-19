// Shared fixtures for armyMovePickerDestinations scenario suites (Refs #4090).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const kArmyMovePickerOw = 'oldWorld';
const kArmyMovePickerNw = 'newWorld';

Army armyMovePickerFieldArmy(
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

final armyMovePickerAdjacencyOw = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: kArmyMovePickerOw,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'P2',
      regionId: kArmyMovePickerOw,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
);

Map<String, String> armyMovePickerVis(List<(String, String)> tiles) {
  return {for (final (_, tk) in tiles) tk: 'fullyVisible'};
}
