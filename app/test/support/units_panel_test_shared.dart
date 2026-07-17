// Shared OW-capital / topology helpers for units-panel widget test families.
//
// Military and naval supports previously each owned adjacent-province and
// capital-adjacent-sea [MapTopology] builders with the same node/edge shape.
// Civilian mini-games factories also need a common human player + OW capital
// province motif. Keep those here so part files and family supports share one
// source (Refs #4021).
//
// SPEC: SPEC/program/repo-lint.md (approved app/test/support harness list).

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Human player with an optional OW capital province + capital tile.
Player buildUnitsPanelHumanPlayer({
  required String id,
  String displayName = 'Human',
  String? capitalProvinceId,
  int capitalX = 0,
  int capitalY = 0,
}) {
  if (capitalProvinceId == null) {
    return Player(id: id, displayName: displayName, isHuman: true);
  }
  return Player(
    id: id,
    displayName: displayName,
    isHuman: true,
    capitalProvinceId: capitalProvinceId,
    capitalTile: CapitalTile(
      regionId: 'oldWorld',
      provinceId: capitalProvinceId,
      x: capitalX,
      y: capitalY,
    ),
  );
}

/// Adjacent OW province pair (army move / locate / invasion adjacency).
MapTopology buildUnitsPanelAdjacentOwProvincesTopology({
  String fromProvinceId = 'oldWorld|p2',
  String toProvinceId = 'oldWorld|p3',
  String regionId = 'oldWorld',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: fromProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: toProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: fromProvinceId, id2: toProvinceId)],
  );
}

/// Capital province adjacent to a named sea zone (naval Combine adjacency).
MapTopology buildUnitsPanelCapitalAdjacentSeaTopology({
  String capitalNodeId = 'oldWorld|cap1',
  String seaZoneId = 'zone_alpha',
  String regionId = 'oldWorld',
  bool includeEdge = true,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: capitalNodeId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaZoneId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      if (includeEdge) TopologyEdge(id1: capitalNodeId, id2: seaZoneId),
    ],
  );
}
