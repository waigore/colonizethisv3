import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show isLegalBlockadeTargetForFleet, isProvinceOwnedByFactionAtWarWith;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

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
