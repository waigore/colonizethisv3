import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'topology_helpers.dart';

/// Movement validation helpers.
/// SPEC/program/movement.md
/// Adjacency is region-scoped when topology has multiple regions (SPEC/game/world-model-identity.md).

/// Province local ids in [regionId] that are adjacent to [localProvinceId] (P–P only).
/// Use this when topology may have duplicate local ids across regions.
/// Handles both prefixed (regionId|localId) and unprefixed topology node ids.
/// Consults cached [topologyAdjacency] rather than scanning all edges (Refs #3978).
Iterable<String> neighborProvinceIdsInRegion(
  MapTopology topology,
  String regionId,
  String localProvinceId,
) sync* {
  final nodeIdsInRegion = provinceNodeIdsForRegion(topology, regionId);
  final localIdsInRegion = nodeIdsInRegion
      .map((id) => ProvinceId.isPrefixed(id) ? ProvinceId.localIdFrom(id) : id)
      .toSet();
  if (!localIdsInRegion.contains(localProvinceId)) return;
  final idToMatch = nodeIdsInRegion.contains(localProvinceId)
      ? localProvinceId
      : ProvinceId.full(regionId, localProvinceId);
  if (!nodeIdsInRegion.contains(idToMatch)) return;
  final neighbors = topologyAdjacency(topology)[idToMatch];
  if (neighbors == null) return;
  for (final other in neighbors) {
    if (nodeIdsInRegion.contains(other)) {
      yield ProvinceId.isPrefixed(other)
          ? ProvinceId.localIdFrom(other)
          : other;
    }
  }
}

/// Validates whether a land move from [fromLocal] to [toLocal] is allowed within [regionId].
/// Use when topology has multiple regions or duplicate local ids (SPEC/game/world-model-identity.md).
bool isValidLandMoveInRegion(
  MapTopology topology,
  String regionId,
  String fromLocal,
  String toLocal,
) {
  if (fromLocal == toLocal) return false;
  return neighborProvinceIdsInRegion(
    topology,
    regionId,
    fromLocal,
  ).contains(toLocal);
}

/// Validates whether a move from [fromProvinceId] to [toProvinceId] is allowed
/// for a land unit using [topology]. Prefer [isValidLandMoveInRegion] when
/// [regionId] is known (required when topology has duplicate local ids across regions).
bool isValidLandMove(
  MapTopology topology,
  String fromProvinceId,
  String toProvinceId,
) {
  if (fromProvinceId == toProvinceId) return false;
  final fromNodes = _provinceNodesForId(topology, fromProvinceId);
  if (!_hasSingleResolvedFromNode(fromNodes)) return false;
  return isValidLandMoveInRegion(
    topology,
    fromNodes.single.regionId,
    fromProvinceId,
    toProvinceId,
  );
}

List<TopologyNode> _provinceNodesForId(
  MapTopology topology,
  String fromProvinceId,
) => topology.nodes
    .where((n) => n.id == fromProvinceId && n.type == TopologyNodeType.province)
    .toList();

bool _hasSingleResolvedFromNode(List<TopologyNode> fromNodes) {
  if (fromNodes.isEmpty) return false;
  if (fromNodes.length > 1) return false;
  return true;
}
