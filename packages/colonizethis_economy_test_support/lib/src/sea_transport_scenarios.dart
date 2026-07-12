// dart format off
// Table-driven sea transport scenarios (Refs #3939 phase 3, #3979).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'sea_transport_expectations.dart';

/// One row in [cargoHoldsForHomeFleetScenarios] (Refs #3979).
typedef CargoHoldsForHomeFleetScenario = ({String label, CargoHoldsPins pins, String? refs});

void runCargoHoldsForHomeFleetScenario(CargoHoldsForHomeFleetScenario scenario) {
  runCargoHoldsExpectation(scenario.pins);
}

/// Canonical scenarios for [cargoHoldsForHomeFleet].
List<CargoHoldsForHomeFleetScenario> cargoHoldsForHomeFleetScenarios() => [
  cargoHoldsScenario(label: 'returns 0 when no home fleet exists', pins: (fleets: null, playerId: 'p1', expectedExact: null, expectNonNegativeOnly: true, parityFleetsById: false)),
  cargoHoldsScenario(
    label: 'sums cargoHold from home-fleet ship types',
    pins: (
      fleets: [
        Fleet(id: 'fleet_p1', ownerId: 'p1', seaZoneId: 'sea1', regionId: 'oldWorld', shipTypeIds: const ['carrack', 'fluyte']),
      ],
      playerId: 'p1',
      expectedExact: NavalStatsCatalog.carrack.cargoHold + NavalStatsCatalog.fluyte.cargoHold,
      expectNonNegativeOnly: false,
      parityFleetsById: false,
    ),
  ),
  cargoHoldsScenario(
    label: 'returns 0 when home fleet has only warship types (cargoHold 0)',
    pins: (
      fleets: [
        Fleet(id: 'fleet_p1', ownerId: 'p1', seaZoneId: 'sea1', regionId: 'oldWorld', shipTypeIds: const ['sloop']),
      ],
      playerId: 'p1',
      expectedExact: 0,
      expectNonNegativeOnly: false,
      parityFleetsById: false,
    ),
  ),
  cargoHoldsScenario(
    label: 'fleetsById index matches default linear home-fleet lookup',
    pins: (
      fleets: [
        Fleet(id: 'fleet_p2', ownerId: 'p2', seaZoneId: 'sea2', regionId: 'oldWorld', shipTypeIds: const ['sloop']),
        Fleet(id: 'fleet_p1', ownerId: 'p1', seaZoneId: 'sea1', regionId: 'oldWorld', shipTypeIds: const ['carrack', 'fluyte']),
      ],
      playerId: 'p1',
      expectedExact: null,
      expectNonNegativeOnly: false,
      parityFleetsById: true,
    ),
  ),
];

/// One row in [allocateOverseasToStockpileScenarios] (Refs #3979).
typedef AllocateOverseasToStockpileScenario = ({String label, AllocateOverseasPins pins, String? refs});

void runAllocateOverseasToStockpileScenario(AllocateOverseasToStockpileScenario scenario) {
  runAllocateOverseasExpectation(scenario.pins);
}

/// Canonical scenarios for [allocateOverseasToStockpile].
List<AllocateOverseasToStockpileScenario> allocateOverseasToStockpileScenarios() => [
  allocateOverseasScenario(label: 'returns empty when overseas is empty', pins: (overseas: {}, cargoHolds: 10, priorityOrder: null, expectEmpty: true, expectedTotal: null, expectedDelivered: null)),
  allocateOverseasScenario(label: 'cargo cap limits delivered overseas', pins: (overseas: {'grain': 5, 'timber': 8, 'iron': 4}, cargoHolds: 10, priorityOrder: null, expectEmpty: false, expectedTotal: 10, expectedDelivered: null)),
  allocateOverseasScenario(label: 'priority order: food before raw materials', pins: (overseas: {'iron': 20, 'grain': 5}, cargoHolds: 6, priorityOrder: null, expectEmpty: false, expectedTotal: null, expectedDelivered: {'grain': 5, 'iron': 1})),
  allocateOverseasScenario(label: 'custom priorityOrder is respected', pins: (overseas: {'grain': 3, 'iron': 10}, cargoHolds: 5, priorityOrder: [CommodityCategory.rawMaterial, CommodityCategory.food], expectEmpty: false, expectedTotal: null, expectedDelivered: {'iron': 5, 'grain': null})),
];
// dart format on
