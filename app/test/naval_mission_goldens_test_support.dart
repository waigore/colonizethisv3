// Fixtures for naval mission dialog widget goldens (Refs #4213).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

export 'naval_mission_goldens_constants.dart';
export 'naval_mission_goldens_war_fixtures.dart';

import 'naval_mission_goldens_constants.dart';
import 'naval_units_panel_ow_fleet_scenarios.dart';
import 'naval_units_panel_test_scenarios.dart';

const Size kNavalMissionGoldenViewport = Size(360, 800);

Game buildNavalMissionMenuPeacetimeGame() =>
    buildNavalPanelNamedSeaZoneGame(humanId: navalMissionGoldenHumanId);

Game buildNavalMissionFleetPickerGame() {
  const capProvince = 'oldWorld|cap1';
  return buildNavalPanelOwFleetsGame(
    gameId: 'naval-mission-picker-golden',
    humanId: navalMissionGoldenHumanId,
    displayName: 'Fleet Picker Tester',
    capitalProvinceId: capProvince,
    oldWorldProvinces: [
      Province(
        id: capProvince,
        regionId: 'oldWorld',
        ownerId: navalMissionGoldenHumanId,
        displayName: 'Capital',
      ),
    ],
    fleets: [
      Fleet(
        id: 'fleet_alpha',
        ownerId: navalMissionGoldenHumanId,
        regionId: 'oldWorld',
        seaZoneId: navalMissionGoldenSeaZone,
        ships: const [ShipInstance(id: 'a1', typeId: 'carrack')],
      ),
      Fleet(
        id: 'fleet_beta',
        ownerId: navalMissionGoldenHumanId,
        regionId: 'oldWorld',
        seaZoneId: navalMissionGoldenSeaZone,
        ships: const [ShipInstance(id: 'b1', typeId: 'galleon')],
      ),
    ],
  );
}
