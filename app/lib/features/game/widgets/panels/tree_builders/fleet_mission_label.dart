import 'package:colonizethis_models/colonizethis_models.dart';

/// User-visible label for [FleetMission] in units panels.
String fleetMissionDisplayLabel(FleetMission m) {
  switch (m) {
    case FleetMission.none:
      return 'None';
    case FleetMission.patrol:
      return 'Patrol';
    case FleetMission.blockade:
      return 'Blockade';
    case FleetMission.beachhead:
      return 'Beachhead';
    case FleetMission.defend:
      return 'Defend';
  }
}

FleetMission fleetMissionFromOrderString(String mission) {
  return FleetMission.values.firstWhere(
    (e) => e.name == mission,
    orElse: () => FleetMission.none,
  );
}
