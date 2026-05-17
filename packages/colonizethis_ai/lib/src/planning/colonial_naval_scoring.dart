import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

/// Sea zones in [kNewWorldRegionId] that border an invadable NW province.
Set<String> newWorldSeaZonesAdjacentToInvadableProvinces(
  MapTopology topology,
  List<String> invadableNewWorldProvinceIdsSorted,
) {
  if (invadableNewWorldProvinceIdsSorted.isEmpty) return const {};
  final invadable = invadableNewWorldProvinceIdsSorted.toSet();
  final adj = <String, Set<String>>{};
  for (final e in topology.edges) {
    adj.putIfAbsent(e.id1, () => <String>{}).add(e.id2);
    adj.putIfAbsent(e.id2, () => <String>{}).add(e.id1);
  }
  final nodeType = <String, TopologyNodeType>{
    for (final n in topology.nodes) n.id: n.type,
  };
  final out = <String>{};
  for (final provId in invadable) {
    for (final nb in adj[provId] ?? const <String>{}) {
      if (nodeType[nb] != TopologyNodeType.seaZone) continue;
      if (ProvinceId.regionIdFrom(nb) != kNewWorldRegionId) continue;
      out.add(nb);
    }
  }
  return out;
}

/// Deterministic score for prioritizing fleet moves toward colonial targets.
int colonialNavalMoveScore(
  NavalMoveOrder move,
  MapTopology topology,
  ColonialSummary colonial,
) {
  final prioritySeas = newWorldSeaZonesAdjacentToInvadableProvinces(
    topology,
    colonial.invadableNewWorldProvinceIdsSorted,
  );

  if (move.isDock) {
    final portId = move.destinationPortProvinceId;
    if (portId != null &&
        portId.isNotEmpty &&
        ProvinceId.regionIdFrom(portId) == kNewWorldRegionId) {
      return kColonialNavalMoveDockNewWorldPortScore;
    }
    return 0;
  }

  final seaId = move.destinationSeaZoneId;
  if (seaId == null || seaId.isEmpty) return 0;

  if (prioritySeas.contains(seaId)) {
    return kColonialNavalMovePriorityNwSeaZoneScore;
  }
  if (ProvinceId.regionIdFrom(seaId) == kNewWorldRegionId) {
    return kColonialNavalMoveNwSeaZoneScore;
  }

  if (_isOldWorldSeaAdjacentToNewWorldSea(topology, seaId)) {
    return kColonialNavalMoveGatewaySeaZoneScore;
  }
  return 0;
}

bool _isOldWorldSeaAdjacentToNewWorldSea(
  MapTopology topology,
  String oldWorldSeaZoneId,
) {
  if (ProvinceId.regionIdFrom(oldWorldSeaZoneId) != kOldWorldRegionId) {
    return false;
  }
  final adj = <String, Set<String>>{};
  for (final e in topology.edges) {
    adj.putIfAbsent(e.id1, () => <String>{}).add(e.id2);
    adj.putIfAbsent(e.id2, () => <String>{}).add(e.id1);
  }
  for (final nb in adj[oldWorldSeaZoneId] ?? const <String>{}) {
    if (ProvinceId.regionIdFrom(nb) == kNewWorldRegionId) return true;
  }
  return false;
}

/// Sort [candidates] by [colonialNavalMoveScore] descending, then stable id order.
List<NavalMoveOrder> sortNavalMovesForColonialPressure(
  List<NavalMoveOrder> candidates,
  MapTopology topology,
  ColonialSummary colonial,
) {
  final scored = candidates
      .map(
        (m) => (
          move: m,
          score: colonialNavalMoveScore(m, topology, colonial),
        ),
      )
      .toList();
  scored.sort((a, b) {
    final s = b.score.compareTo(a.score);
    if (s != 0) return s;
    final fleet = a.move.fleetId.compareTo(b.move.fleetId);
    if (fleet != 0) return fleet;
    final keyA = a.move.isDock
        ? 'port:${a.move.destinationPortProvinceId}'
        : (a.move.destinationSeaZoneId ?? '');
    final keyB = b.move.isDock
        ? 'port:${b.move.destinationPortProvinceId}'
        : (b.move.destinationSeaZoneId ?? '');
    return keyA.compareTo(keyB);
  });
  return scored.map((e) => e.move).toList();
}
