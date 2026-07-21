import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
void runCargoHoldsExpectation(CargoHoldsPins pins) {
  final game = minimalEconomyGame(
    fleets: pins.fleets,
    players: [Player(id: pins.playerId, displayName: 'P1', isHuman: true)],
  );
  if (pins.parityFleetsById) {
    final byId = fleetsByIdForWorld(game.worldState);
    expect(cargoHoldsForHomeFleet(game, pins.playerId, fleetsById: byId), cargoHoldsForHomeFleet(game, pins.playerId));
    return;
  }
  final holds = cargoHoldsForHomeFleet(game, pins.playerId);
  if (pins.expectNonNegativeOnly) {
    expect(holds, greaterThanOrEqualTo(0));
  } else if (pins.expectedExact != null) {
    expect(holds, pins.expectedExact);
  }
}

void runCargoHoldsForHomeFleetScenario(CargoHoldsForHomeFleetScenario scenario) {
  runCargoHoldsExpectation(scenario.pins);
}

void runAllocateOverseasExpectation(AllocateOverseasPins pins) {
  final delivered = allocateOverseasToStockpile(pins.overseas, cargoHolds: pins.cargoHolds, priorityOrder: pins.priorityOrder);
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

void runAllocateOverseasToStockpileScenario(AllocateOverseasToStockpileScenario scenario) {
  runAllocateOverseasExpectation(scenario.pins);
}
// dart format on

void main() {
  runLabeledScenarioGroup(
    'cargoHoldsForHomeFleet',
    cargoHoldsForHomeFleetScenarios(),
    runCargoHoldsForHomeFleetScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'SeaTransport allocateOverseasToStockpile',
    allocateOverseasToStockpileScenarios(),
    runAllocateOverseasToStockpileScenario,
    labelOf: (s) => s.label,
  );
}
