import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'colonial_naval_topology_context.dart';
import 'scored_candidate.dart';

/// Sea zones in [kNewWorldRegionId] that border an invadable NW province.
Set<String> newWorldSeaZonesAdjacentToInvadableProvinces(
  MapTopology topology,
  List<String> invadableNewWorldProvinceIdsSorted,
) {
  return ColonialNavalTopologyContext.fromTopology(
    topology,
  ).newWorldSeaZonesAdjacentToInvadableProvinces(
    invadableNewWorldProvinceIdsSorted,
  );
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
  return colonialNavalMoveScoreWithContext(
    move,
    ColonialNavalTopologyContext.fromTopology(topology),
    colonial,
    phasePriorityNwProvinceIdsSorted: phasePriorityNwProvinceIdsSorted,
  );
}

int colonialNavalMoveScoreWithContext(
  NavalMoveOrder move,
  ColonialNavalTopologyContext topologyContext,
  ColonialSummary colonial, {
  List<String>? phasePriorityNwProvinceIdsSorted,
}) {
  final prioritySeas = topologyContext.newWorldSeaZonesAdjacentToInvadableProvinces(
    colonial.invadableNewWorldProvinceIdsSorted,
  );
  final phasePrioritySeas =
      (phasePriorityNwProvinceIdsSorted == null ||
          phasePriorityNwProvinceIdsSorted.isEmpty)
      ? const <String>{}
      : topologyContext.newWorldSeaZonesAdjacentToInvadableProvinces(
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

  if (topologyContext.isOldWorldSeaAdjacentToNewWorldSea(seaId)) {
    return kColonialNavalMoveGatewaySeaZoneScore;
  }
  return 0;
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
  final topologyContext = ColonialNavalTopologyContext.fromTopology(topology);
  return sortByScore(
    candidates.map(
      (move) => ScoredCandidate(
        item: move,
        score: colonialNavalMoveScoreWithContext(
          move,
          topologyContext,
          colonial,
          phasePriorityNwProvinceIdsSorted: phasePriorityNwProvinceIdsSorted,
        ),
      ),
    ),
    (a, b) {
      final fleet = a.fleetId.compareTo(b.fleetId);
      if (fleet != 0) return fleet;
      final keyA = a.isDock
          ? 'port:${a.destinationPortProvinceId}'
          : (a.destinationSeaZoneId ?? '');
      final keyB = b.isDock
          ? 'port:${b.destinationPortProvinceId}'
          : (b.destinationSeaZoneId ?? '');
      return keyA.compareTo(keyB);
    },
  );
}

/// Deterministic score for naval missions under colonial pressure.
///
/// When [phasePriorityNwProvinceIdsSorted] is non-empty (Refs #2509 S5 —
/// the phase-planner naval directive surfaces a tighter NW priority subset
/// of [ColonialSummary.invadableNewWorldProvinceIdsSorted]), a NW port
/// mission whose [NavalMissionOrder.targetPortId] is in that subset earns
/// [kColonialNavalMissionPhasePriorityNwPortScore] (200), one tier above
/// [kColonialNavalMissionNwPortScore] (160). A NW province mission whose
/// [NavalMissionOrder.targetProvinceId] is in the subset earns
/// [kColonialNavalMissionPhasePriorityNwProvinceScore] (170), one tier
/// above [kColonialNavalMissionNwProvinceScore] (130). Missions targeting
/// other NW ports / provinces still earn the existing NW tiers; beachhead
/// and OW branches are unaffected. Passing `null` or an empty list
/// preserves legacy three-tier scoring exactly.
int colonialNavalMissionScore(
  NavalMissionOrder mission, {
  List<String>? phasePriorityNwProvinceIdsSorted,
}) {
  final phasePriority =
      (phasePriorityNwProvinceIdsSorted == null ||
          phasePriorityNwProvinceIdsSorted.isEmpty)
      ? const <String>{}
      : phasePriorityNwProvinceIdsSorted.toSet();

  final portId = mission.targetPortId;
  if (portId != null &&
      portId.isNotEmpty &&
      ProvinceId.regionIdFrom(portId) == kNewWorldRegionId) {
    if (phasePriority.contains(portId)) {
      return kColonialNavalMissionPhasePriorityNwPortScore;
    }
    return kColonialNavalMissionNwPortScore;
  }
  final provId = mission.targetProvinceId;
  if (provId != null &&
      provId.isNotEmpty &&
      ProvinceId.regionIdFrom(provId) == kNewWorldRegionId) {
    if (phasePriority.contains(provId)) {
      return kColonialNavalMissionPhasePriorityNwProvinceScore;
    }
    return kColonialNavalMissionNwProvinceScore;
  }
  if (mission.mission == FleetMission.beachhead.name) {
    return kColonialNavalMissionBeachheadScore;
  }
  return 0;
}

/// Sort [candidates] by [colonialNavalMissionScore] descending, then stable id order.
///
/// Pass [phasePriorityNwProvinceIdsSorted] from the phase-planner naval
/// directive (Refs #2509 S5) to elevate NW-port / NW-province missions
/// targeting phase-active provinces above the general NW tiers. `null` or
/// empty preserves legacy ordering.
List<NavalMissionOrder> sortNavalMissionsForColonialPressure(
  List<NavalMissionOrder> candidates, {
  List<String>? phasePriorityNwProvinceIdsSorted,
}) {
  return sortByScore(
    candidates.map(
      (mission) => ScoredCandidate(
        item: mission,
        score: colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityNwProvinceIdsSorted,
        ),
      ),
    ),
    (a, b) {
      final fleet = a.fleetId.compareTo(b.fleetId);
      if (fleet != 0) return fleet;
      final missionCmp = a.mission.compareTo(b.mission);
      if (missionCmp != 0) return missionCmp;
      final portA = a.targetPortId ?? '';
      final portB = b.targetPortId ?? '';
      final portCmp = portA.compareTo(portB);
      if (portCmp != 0) return portCmp;
      return (a.targetProvinceId ?? '').compareTo(b.targetProvinceId ?? '');
    },
  );
}
