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
///
/// When [phasePriorityNwProvinceIdsSorted] is non-empty (Refs #2509 S5 —
/// the phase-planner naval directive surfaces a tighter NW priority subset
/// of [ColonialSummary.invadableNewWorldProvinceIdsSorted]), NW sea zones
/// adjacent to a province in that subset earn
/// [kColonialNavalMovePhasePriorityNwSeaZoneScore] (240), one tier above
/// the general invadable-NW priority score (200). Sea zones adjacent to
/// other invadable NW provinces (not in the phase subset) still earn the
/// existing [kColonialNavalMovePriorityNwSeaZoneScore]. Passing `null` or
/// an empty list preserves legacy scoring exactly.
int colonialNavalMoveScore(
  NavalMoveOrder move,
  MapTopology topology,
  ColonialSummary colonial, {
  List<String>? phasePriorityNwProvinceIdsSorted,
}) {
  final prioritySeas = newWorldSeaZonesAdjacentToInvadableProvinces(
    topology,
    colonial.invadableNewWorldProvinceIdsSorted,
  );
  final phasePrioritySeas =
      (phasePriorityNwProvinceIdsSorted == null ||
          phasePriorityNwProvinceIdsSorted.isEmpty)
      ? const <String>{}
      : newWorldSeaZonesAdjacentToInvadableProvinces(
          topology,
          phasePriorityNwProvinceIdsSorted,
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

  if (phasePrioritySeas.contains(seaId)) {
    return kColonialNavalMovePhasePriorityNwSeaZoneScore;
  }
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
///
/// Pass [phasePriorityNwProvinceIdsSorted] from the phase-planner naval
/// directive (Refs #2509 S5) to elevate NW sea zones adjacent to phase-active
/// invadable provinces above the general invadable-NW priority tier. `null`
/// or empty preserves legacy ordering.
List<NavalMoveOrder> sortNavalMovesForColonialPressure(
  List<NavalMoveOrder> candidates,
  MapTopology topology,
  ColonialSummary colonial, {
  List<String>? phasePriorityNwProvinceIdsSorted,
}) {
  final scored = candidates
      .map(
        (m) => (
          move: m,
          score: colonialNavalMoveScore(
            m,
            topology,
            colonial,
            phasePriorityNwProvinceIdsSorted: phasePriorityNwProvinceIdsSorted,
          ),
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

/// Deterministic score for naval missions under colonial pressure.
int colonialNavalMissionScore(NavalMissionOrder mission) {
  final portId = mission.targetPortId;
  if (portId != null &&
      portId.isNotEmpty &&
      ProvinceId.regionIdFrom(portId) == kNewWorldRegionId) {
    return kColonialNavalMissionNwPortScore;
  }
  final provId = mission.targetProvinceId;
  if (provId != null &&
      provId.isNotEmpty &&
      ProvinceId.regionIdFrom(provId) == kNewWorldRegionId) {
    return kColonialNavalMissionNwProvinceScore;
  }
  if (mission.mission == FleetMission.beachhead.name) {
    return kColonialNavalMissionBeachheadScore;
  }
  return 0;
}

/// Sort [candidates] by [colonialNavalMissionScore] descending, then stable id order.
List<NavalMissionOrder> sortNavalMissionsForColonialPressure(
  List<NavalMissionOrder> candidates,
) {
  final scored = candidates
      .map((m) => (mission: m, score: colonialNavalMissionScore(m)))
      .toList();
  scored.sort((a, b) {
    final s = b.score.compareTo(a.score);
    if (s != 0) return s;
    final fleet = a.mission.fleetId.compareTo(b.mission.fleetId);
    if (fleet != 0) return fleet;
    final missionCmp = a.mission.mission.compareTo(b.mission.mission);
    if (missionCmp != 0) return missionCmp;
    final portA = a.mission.targetPortId ?? '';
    final portB = b.mission.targetPortId ?? '';
    final portCmp = portA.compareTo(portB);
    if (portCmp != 0) return portCmp;
    return (a.mission.targetProvinceId ?? '').compareTo(
      b.mission.targetProvinceId ?? '',
    );
  });
  return scored.map((e) => e.mission).toList();
}
