// Civilian-missing-work fixtures for next-turn confirmation goldens (#4140).
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show CivilianMissingWorkOrderEntry;

const kNextTurnConfirmSeveralCivilians = [
  CivilianMissingWorkOrderEntry(
    unitId: 'e1',
    type: 'explorer',
    tileKey: 'oldWorld|p1|0|0',
    regionId: 'oldWorld',
    locationLabel: 'Old World — Alpha Province',
  ),
  CivilianMissingWorkOrderEntry(
    unitId: 'b1',
    type: 'builder',
    tileKey: 'oldWorld|p2|1|0',
    regionId: 'oldWorld',
    locationLabel: 'Old World — Beta Province',
  ),
  CivilianMissingWorkOrderEntry(
    unitId: 's1',
    type: 'spy',
    tileKey: 'newWorld|p3|2|1',
    regionId: 'newWorld',
    locationLabel: 'New World — Gamma Province',
  ),
];
