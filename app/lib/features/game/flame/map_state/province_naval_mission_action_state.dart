import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        isLegalBlockadeTargetForFleet,
        isProvinceOwnedByFactionAtWarWith,
        navalMissionAvailabilityForFleet;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/prefixed_id.dart';
import '../overlays/province_blockade_status_support.dart';

/// Visibility/enablement for MAP20001 Naval Blockade / Beachhead (Refs #4413).
///
/// Visibility uses cheap topology/ownership/war predicates; enablement reads
/// `isLegalBlockadeTargetForFleet` / `isLegalBeachheadTargetForFleet` only —
/// never the suggestion/order-engine on overlay paint.
class ProvinceNavalMissionActionState {
  const ProvinceNavalMissionActionState({
    required this.showControls,
    required this.enabled,
    required this.eligibleFleetIds,
  });

  static const hidden = ProvinceNavalMissionActionState(
    showControls: false,
    enabled: false,
    eligibleFleetIds: <String>[],
  );

  final bool showControls;
  final bool enabled;
  final List<String> eligibleFleetIds;
}

/// Overlay Naval Blockade/Beachhead control props (Refs #4413).
class ProvinceNavalMissionOverlayControls {
  const ProvinceNavalMissionOverlayControls({
    this.showBlockade = false,
    this.blockadeEnabled = false,
    this.blockadeTooltip = '',
    this.onBlockadeTap,
    this.showBeachhead = false,
    this.beachheadEnabled = false,
    this.beachheadTooltip = '',
    this.onBeachheadTap,
    this.showPatrol = false,
    this.patrolEnabled = false,
    this.patrolTooltip = '',
    this.onPatrolTap,
    this.showDefend = false,
    this.defendEnabled = false,
    this.defendTooltip = '',
    this.onDefendTap,
    this.blockadeStatus = ProvinceBlockadeStatus.none,
  });

  static const hidden = ProvinceNavalMissionOverlayControls();

  final bool showBlockade;
  final bool blockadeEnabled;
  final String blockadeTooltip;
  final VoidCallback? onBlockadeTap;
  final bool showBeachhead;
  final bool beachheadEnabled;
  final String beachheadTooltip;
  final VoidCallback? onBeachheadTap;
  final bool showPatrol;
  final bool patrolEnabled;
  final String patrolTooltip;
  final VoidCallback? onPatrolTap;
  final bool showDefend;
  final bool defendEnabled;
  final String defendTooltip;
  final VoidCallback? onDefendTap;
  final ProvinceBlockadeStatus blockadeStatus;
}

/// Computes Patrol/Defend action state for a sea-zone overlay (Refs #4605).
///
/// Visibility is in-zone human non-Home at-sea fleets. Enablement requires
/// [navalMissionAvailabilityForFleet] base gates plus a free move-xor-mission
/// slot (no world-state mission, pending mission, or pending naval move).
ProvinceNavalMissionActionState computeSeaZoneNavalStayMissionActionState({
  required Game game,
  required String humanPlayerId,
  required String seaZoneId,
  required MapTopology topology,
  required Orders draftOrders,
}) {
  final homeId = homeFleetIdFor(humanPlayerId);
  final localSea = prefixedIdLocalSegment(seaZoneId);
  final regionId = prefixedIdRegionSegment(seaZoneId);
  final inZone = <Fleet>[
    for (final fleet in game.worldState.fleets)
      if (fleet.ownerId == humanPlayerId &&
          fleet.id != homeId &&
          fleet.isAtSea &&
          fleet.seaZoneId != null &&
          fleet.seaZoneId == localSea &&
          (regionId == null || fleet.regionId == regionId))
        fleet,
  ];
  if (inZone.isEmpty) return ProvinceNavalMissionActionState.hidden;

  final pendingMoves =
      draftOrders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const [];
  final eligible = <String>[];
  for (final fleet in inZone) {
    final availability = navalMissionAvailabilityForFleet(
      game: game,
      topology: topology,
      playerId: humanPlayerId,
      fleet: fleet,
      currentOrders: draftOrders,
    );
    final hasPendingMove = pendingMoves.any((o) => o.fleetId == fleet.id);
    if (availability.baseGatesPass &&
        fleet.mission == FleetMission.none &&
        !availability.hasPendingMission &&
        !hasPendingMove) {
      eligible.add(fleet.id);
    }
  }
  eligible.sort();
  return ProvinceNavalMissionActionState(
    showControls: true,
    enabled: eligible.isNotEmpty,
    eligibleFleetIds: eligible,
  );
}

/// Computes Blockade/Beachhead action state for [provinceId] (prefixed full id).
ProvinceNavalMissionActionState computeProvinceNavalMissionActionState({
  required Game game,
  required String humanPlayerId,
  required String provinceId,
  required MapTopology topology,
  required bool isSeaZoneContext,
}) {
  if (isSeaZoneContext) return ProvinceNavalMissionActionState.hidden;

  final province = game.worldState.tryGetProvince(provinceId);
  if (province == null) return ProvinceNavalMissionActionState.hidden;

  final ownerId = province.ownerId;
  if (ownerId == null || ownerId.isEmpty || ownerId == humanPlayerId) {
    return ProvinceNavalMissionActionState.hidden;
  }
  if (!isProvinceOwnedByFactionAtWarWith(
    game: game,
    playerId: humanPlayerId,
    fullProvinceId: provinceId,
  )) {
    return ProvinceNavalMissionActionState.hidden;
  }
  if (seaZonesAdjacentToProvince(topology, provinceId).isEmpty) {
    return ProvinceNavalMissionActionState.hidden;
  }

  final homeId = homeFleetIdFor(humanPlayerId);
  final atSeaSeaGoing = <Fleet>[
    for (final fleet in game.worldState.fleets)
      if (fleet.ownerId == humanPlayerId &&
          fleet.id != homeId &&
          fleet.isAtSea &&
          fleet.seaZoneId != null)
        fleet,
  ];
  if (atSeaSeaGoing.isEmpty) return ProvinceNavalMissionActionState.hidden;

  final eligible = <String>[
    for (final fleet in atSeaSeaGoing)
      if (isLegalBlockadeTargetForFleet(
        game: game,
        topology: topology,
        playerId: humanPlayerId,
        fleet: fleet,
        targetProvinceId: provinceId,
      ))
        fleet.id,
  ]..sort();

  return ProvinceNavalMissionActionState(
    showControls: true,
    enabled: eligible.isNotEmpty,
    eligibleFleetIds: eligible,
  );
}
