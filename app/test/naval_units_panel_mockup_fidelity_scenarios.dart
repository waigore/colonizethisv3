// Mockup-fidelity scenario for naval units panel (Refs #2866 S8, #4021).

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_units_panel_ow_fleet_scenarios.dart';

const kNavalMockupFidelityHumanId = 'gp_naval_fidelity';

/// Deterministic mockup-fidelity scenario (Refs #2866 S8, #4021).
Game buildNavalPanelMockupFidelityGame() {
  const humanId = kNavalMockupFidelityHumanId;
  const capitalProvinceId = 'oldWorld|cap1';
  const portProvinceId = 'oldWorld|port1';
  const zonePrefixedId = 'oldWorld|zone_alpha';
  final homeId = homeFleetIdFor(humanId);
  return buildNavalPanelOwFleetsGame(
    gameId: 'naval-fidelity',
    humanId: humanId,
    displayName: 'Fidelity Tester',
    capitalProvinceId: capitalProvinceId,
    oldWorldProvinces: const [
      Province(
        id: 'cap1',
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'London',
      ),
      Province(
        id: 'port1',
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Portsmouth',
      ),
    ],
    fleets: [
      Fleet(
        id: homeId,
        ownerId: humanId,
        regionId: 'oldWorld',
        inPortAtProvinceId: capitalProvinceId,
        ships: const [
          ShipInstance(id: 'h1', typeId: 'carrack'),
          ShipInstance(id: 'h2', typeId: 'frigate'),
        ],
      ),
      Fleet(
        id: 'channel_fleet',
        ownerId: humanId,
        regionId: 'oldWorld',
        inPortAtProvinceId: portProvinceId,
        ships: const [
          ShipInstance(id: 'p1', typeId: 'frigate'),
          ShipInstance(id: 'p2', typeId: 'frigate'),
        ],
      ),
      Fleet(
        id: 'atlantic_fleet',
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: 'zone_alpha',
        ships: const [ShipInstance(id: 's1', typeId: 'galleon')],
      ),
    ],
    seaZoneDisplayNameById: const {zonePrefixedId: 'Bay of Biscay'},
    tileKeysByProvince: const {
      capitalProvinceId: ['oldWorld|cap1|0|0'],
      portProvinceId: ['oldWorld|port1|0|0'],
    },
  );
}
