import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Movement validation and application.
/// SPEC/program/movement.md
/// Adjacency is region-scoped when topology has multiple regions (SPEC/game/world-model-identity.md).

/// Province local ids in [regionId] that are adjacent to [localProvinceId] (P–P only).
/// Use this when topology may have duplicate local ids across regions.
Iterable<String> neighborProvinceIdsInRegion(
  MapTopology topology,
  String regionId,
  String localProvinceId,
) sync* {
  final provinceIdsInRegion = topology.nodes
      .where((n) =>
          n.regionId == regionId && n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
  if (!provinceIdsInRegion.contains(localProvinceId)) return;
  for (final edge in topology.edges) {
    if (edge.id1 != localProvinceId && edge.id2 != localProvinceId) continue;
    final other = edge.id1 == localProvinceId ? edge.id2 : edge.id1;
    if (provinceIdsInRegion.contains(other)) yield other;
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
  return neighborProvinceIdsInRegion(topology, regionId, fromLocal)
      .contains(toLocal);
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
  final fromNodes = topology.nodes
      .where((n) =>
          n.id == fromProvinceId && n.type == TopologyNodeType.province)
      .toList();
  if (fromNodes.isEmpty) return false;
  if (fromNodes.length > 1) {
    // Duplicate local id across regions; cannot decide without regionId.
    return false;
  }
  return isValidLandMoveInRegion(
    topology,
    fromNodes.single.regionId,
    fromProvinceId,
    toProvinceId,
  );
}

/// Applies all MoveOrders in [orders] to the units in [regionData], returning
/// an updated RegionData. Invalid moves are ignored.
///
/// For **civilian** units (have [tileKey]), sets [tileKey] to a tile in the destination
/// province when [tileKeysByRegionAndProvince] and [regionId] are provided; otherwise
/// only [provinceId] is updated. For **military** units (no tileKey), updates [provinceId] only.
RegionData applyMoveOrdersToRegion(
  RegionData regionData,
  MapTopology topology,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId, {
  String? regionId,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
}) {
  if (moveOrdersByPlayerId.isEmpty || regionData.units.isEmpty) {
    return regionData;
  }

  final unitsById = {
    for (final u in regionData.units) u.id: u,
  };

  for (final entry in moveOrdersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      final unit = unitsById[order.unitId];
      if (unit == null || unit.ownerId != playerId) continue;
      final currentProvinceId = unit.locationProvinceId;
      final destProvinceId = order.destinationProvinceId;
      if (regionId != null && ProvinceId.isPrefixed(destProvinceId) &&
          ProvinceId.regionIdFrom(destProvinceId) != regionId) {
        continue; // Land move cannot cross regions.
      }
      // Normalize to prefixed form when regionId known (SPEC/game/world-model-identity.md).
      final destFullId = regionId != null && !ProvinceId.isPrefixed(destProvinceId)
          ? ProvinceId.full(regionId, destProvinceId)
          : destProvinceId;
      // Topology uses local province ids; validate using region-scoped adjacency when region known.
      final fromLocal = ProvinceId.localIdFrom(currentProvinceId);
      final toLocal = ProvinceId.localIdFrom(destFullId);
      final valid = regionId != null
          ? isValidLandMoveInRegion(topology, regionId!, fromLocal, toLocal)
          : isValidLandMove(topology, fromLocal, toLocal);
      if (!valid) {
        continue;
      }
      final isCivilian = unit.tileKey != null && unit.tileKey!.isNotEmpty;
      final firstTileInDest = regionId != null &&
              tileKeysByRegionAndProvince != null &&
              (tileKeysByRegionAndProvince[regionId]?[destFullId]?.isNotEmpty ?? false)
          ? tileKeysByRegionAndProvince[regionId]![destFullId]!.first
          : null;
      if (isCivilian && firstTileInDest != null) {
        unitsById[unit.id] = unit.copyWith(
          provinceId: destFullId,
          tileKey: firstTileInDest,
        );
      } else {
        unitsById[unit.id] = unit.copyWith(provinceId: destFullId);
      }
    }
  }

  return RegionData(
    provinces: regionData.provinces,
    units: unitsById.values.toList(),
  );
}

