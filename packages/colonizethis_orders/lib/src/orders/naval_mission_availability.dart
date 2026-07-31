import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'naval_mission_targets.dart';

/// One assignable mission row for human naval mission UI.
class NavalMissionOption {
  const NavalMissionOption({
    required this.mission,
    this.disabledReason,
  });

  final FleetMission mission;

  /// When non-null, the mission must not be offered as an enabled control.
  final String? disabledReason;

  bool get isEnabled => disabledReason == null;
}

/// Legal mission assign / cancel-pending state for one fleet.
class NavalMissionAvailability {
  const NavalMissionAvailability({
    required this.missions,
    required this.blockadeTargetProvinceIds,
    required this.beachheadTargetProvinceIds,
    required this.hasPendingMission,
    required this.canCancelPending,
    required this.baseGatesPass,
  });

  final List<NavalMissionOption> missions;
  final List<String> blockadeTargetProvinceIds;
  final List<String> beachheadTargetProvinceIds;
  final bool hasPendingMission;
  final bool canCancelPending;
  final bool baseGatesPass;
}

NavalMissionAvailability navalMissionAvailabilityForFleet({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Fleet fleet,
  required Orders currentOrders,
}) {
  final homeFleetId = homeFleetIdFor(playerId);
  final pendingMissions =
      currentOrders.navalMissionOrdersByPlayerId[playerId] ?? const [];
  final hasPendingMission = pendingMissions.any((o) => o.fleetId == fleet.id);

  final baseGatesPass =
      fleet.ownerId == playerId &&
      fleet.id != homeFleetId &&
      fleet.isAtSea &&
      fleet.seaZoneId != null;

  if (!baseGatesPass) {
    return NavalMissionAvailability(
      missions: const [],
      blockadeTargetProvinceIds: const [],
      beachheadTargetProvinceIds: const [],
      hasPendingMission: hasPendingMission,
      canCancelPending: hasPendingMission,
      baseGatesPass: false,
    );
  }

  final hostileCoastal = hostileCoastalProvinceTargetsForFleet(
    game: game,
    topology: topology,
    playerId: playerId,
    fleet: fleet,
  );

  final missions = <NavalMissionOption>[
    const NavalMissionOption(mission: FleetMission.patrol),
    const NavalMissionOption(mission: FleetMission.defend),
    if (hostileCoastal.isNotEmpty)
      const NavalMissionOption(mission: FleetMission.blockade)
    else
      const NavalMissionOption(
        mission: FleetMission.blockade,
        disabledReason: 'No adjacent provinces owned by factions at war',
      ),
    if (hostileCoastal.isNotEmpty)
      const NavalMissionOption(mission: FleetMission.beachhead)
    else
      const NavalMissionOption(
        mission: FleetMission.beachhead,
        disabledReason: 'No hostile coastal provinces adjacent to this sea zone',
      ),
  ];

  return NavalMissionAvailability(
    missions: missions,
    blockadeTargetProvinceIds: hostileCoastal,
    beachheadTargetProvinceIds: hostileCoastal,
    hasPendingMission: hasPendingMission,
    canCancelPending: hasPendingMission,
    baseGatesPass: true,
  );
}
