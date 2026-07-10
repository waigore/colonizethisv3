// Compact sea transport assertions (Refs #3939 phase 3 slice 36).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'sea_transport_scenarios.dart';

/// Pins for [cargoHoldsForHomeFleet] rows.
typedef CargoHoldsPins = ({
  List<Fleet>? fleets,
  String playerId,
  int? expectedExact,
  bool expectNonNegativeOnly,
  bool parityFleetsById,
});

void runCargoHoldsExpectation(CargoHoldsPins pins) {
  final game = minimalEconomyGame(
    fleets: pins.fleets,
    players: [Player(id: pins.playerId, displayName: 'P1', isHuman: true)],
  );
  if (pins.parityFleetsById) {
    final byId = fleetsByIdForWorld(game.worldState);
    expect(
      cargoHoldsForHomeFleet(game, pins.playerId, fleetsById: byId),
      cargoHoldsForHomeFleet(game, pins.playerId),
    );
    return;
  }
  final holds = cargoHoldsForHomeFleet(game, pins.playerId);
  if (pins.expectNonNegativeOnly) {
    expect(holds, greaterThanOrEqualTo(0));
  } else if (pins.expectedExact != null) {
    expect(holds, pins.expectedExact);
  }
}

CargoHoldsForHomeFleetScenario cargoHoldsScenario({
  required String label,
  required CargoHoldsPins pins,
}) =>
    CargoHoldsForHomeFleetScenario(
      label: label,
      run: () => runCargoHoldsExpectation(pins),
    );

/// Pins for [allocateOverseasToStockpile] rows.
typedef AllocateOverseasPins = ({
  Map<String, int> overseas,
  int cargoHolds,
  List<CommodityCategory>? priorityOrder,
  bool expectEmpty,
  int? expectedTotal,
  Map<String, int?>? expectedDelivered,
});

void runAllocateOverseasExpectation(AllocateOverseasPins pins) {
  final delivered = allocateOverseasToStockpile(
    pins.overseas,
    cargoHolds: pins.cargoHolds,
    priorityOrder: pins.priorityOrder,
  );
  if (pins.expectEmpty) {
    expect(delivered, isEmpty);
    return;
  }
  if (pins.expectedTotal != null) {
    final total = delivered.values.fold<int>(0, (a, b) => a + b);
    expect(total, lessThanOrEqualTo(pins.cargoHolds));
    expect(total, pins.expectedTotal);
  }
  final expectedDelivered = pins.expectedDelivered;
  if (expectedDelivered != null) {
    for (final entry in expectedDelivered.entries) {
      if (entry.value == null) {
        expect(delivered[entry.key], isNull);
      } else {
        expect(delivered[entry.key], entry.value);
      }
    }
  }
}

AllocateOverseasToStockpileScenario allocateOverseasScenario({
  required String label,
  required AllocateOverseasPins pins,
}) =>
    AllocateOverseasToStockpileScenario(
      label: label,
      run: () => runAllocateOverseasExpectation(pins),
    );
