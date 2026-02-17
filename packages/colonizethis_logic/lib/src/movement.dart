import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Movement validation and application.
/// SPEC/program/movement.md

/// Computes neighboring province ids (excluding sea zones) for [provinceId].
Iterable<String> _neighborProvinceIds(
  MapTopology topology,
  String provinceId,
) sync* {
  for (final edge in topology.edges) {
    if (edge.id1 == provinceId) {
      final node = topology.nodes.firstWhere(
        (n) => n.id == edge.id2,
        orElse: () => TopologyNode(
          id: edge.id2,
          regionId: '',
          type: TopologyNodeType.seaZone,
        ),
      );
      if (node.type == TopologyNodeType.province) {
        yield node.id;
      }
    } else if (edge.id2 == provinceId) {
      final node = topology.nodes.firstWhere(
        (n) => n.id == edge.id1,
        orElse: () => TopologyNode(
          id: edge.id1,
          regionId: '',
          type: TopologyNodeType.seaZone,
        ),
      );
      if (node.type == TopologyNodeType.province) {
        yield node.id;
      }
    }
  }
}

/// Validates whether a move from [fromProvinceId] to [toProvinceId] is allowed
/// for a land unit using [topology].
bool isValidLandMove(
  MapTopology topology,
  String fromProvinceId,
  String toProvinceId,
) {
  if (fromProvinceId == toProvinceId) return false;
  return _neighborProvinceIds(topology, fromProvinceId).contains(toProvinceId);
}

/// Applies all MoveOrders in [orders] to the units in [regionData], returning
/// an updated RegionData. Invalid moves are ignored.
RegionData applyMoveOrdersToRegion(
  RegionData regionData,
  MapTopology topology,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId,
) {
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
      if (!isValidLandMove(
        topology,
        unit.provinceId,
        order.destinationProvinceId,
      )) {
        continue;
      }
      unitsById[unit.id] = unit.copyWith(provinceId: order.destinationProvinceId);
    }
  }

  return RegionData(
    provinces: regionData.provinces,
    units: unitsById.values.toList(),
  );
}

