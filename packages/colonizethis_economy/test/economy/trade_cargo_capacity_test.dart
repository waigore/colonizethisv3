import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
void runOverseasShippedTonnageExpectation(OverseasShippedTonnagePins pins) {
  for (final caseRow in pins.cases) {
    expect(overseasShippedTonnageFromExtractionTotals(caseRow.overseasTotals, homeFleetCargoHolds: caseRow.homeFleetCargoHolds), caseRow.expected);
  }
}

void runOverseasShippedTonnageScenario(OverseasShippedTonnageScenario scenario) {
  runOverseasShippedTonnageExpectation(scenario.pins);
}

void runTradeCargoCapacityEmptyTileMapsExpectation() {
  final game = minimalGpGame();
  expect(
    tradeCargoCapacityForGreatPower(
      game: game,
      playerId: 'gp1',
      tileMapByRegion: const {},
      topology: const MapTopology(nodes: [], edges: []),
    ),
    cargoHoldsForHomeFleet(game, 'gp1'),
  );
}

void runTradeCargoCapacityGpExpectation(TradeCargoCapacityGpTarget target) {
  switch (target) {
    case TradeCargoCapacityGpTarget.emptyTileMaps:
      runTradeCargoCapacityEmptyTileMapsExpectation();
  }
}

void runTradeCargoCapacityForGreatPowerScenario(TradeCargoCapacityForGreatPowerScenario scenario) {
  runTradeCargoCapacityGpExpectation(scenario.target);
}

final Map<String, TileMapResult> _nonEmptyTileMapForTradeCargo = {
  'r1': TileMapResult(
    width: 1,
    height: 1,
    grid: const [
      ['p1'],
    ],
  ),
};

const MapTopology _emptyTopologyForTradeCargo = MapTopology(nodes: [], edges: []);

void runForecastOverseasTonnageExpectation(ForecastOverseasTonnagePins pins) {
  final game = minimalGpGame(playerId: pins.playerId);
  final shipped = forecastOverseasShippedTonnageForPlayer(game: game, playerId: pins.playerId, tileMapByRegion: _nonEmptyTileMapForTradeCargo, topology: _emptyTopologyForTradeCargo, extractionById: pins.extractionById);
  if (pins.deriveOverseasTotals != null) {
    expect(shipped, overseasShippedTonnageFromExtractionTotals(pins.deriveOverseasTotals!, homeFleetCargoHolds: cargoHoldsForHomeFleet(game, pins.playerId)));
  }
  if (pins.expectedExact != null) {
    expect(shipped, pins.expectedExact);
  }
}

void runTradeCargoCapacityExtractionExpectation(TradeCargoCapacityExtractionPins pins) {
  final game = minimalGpGame(playerId: pins.playerId);
  final holds = cargoHoldsForHomeFleet(game, pins.playerId);
  final capacity = tradeCargoCapacityForGreatPower(game: game, playerId: pins.playerId, tileMapByRegion: _nonEmptyTileMapForTradeCargo, topology: _emptyTopologyForTradeCargo, extractionById: pins.extractionById);
  expect(capacity, holds - pins.overseasTonnageSubtracted);
}

void runComputeExtractionTotalsEmptyMapsExpectation() {
  final game = minimalGpGame(playerId: 'gp1');
  expect(computeExtractionTotalsForTradeForecast(game: game, tileMapByRegion: const {}, topology: _emptyTopologyForTradeCargo), isEmpty);
}

void runExtractionByIdBypassScenario(ExtractionByIdBypassScenario scenario) {
  switch (scenario.kind) {
    case ExtractionByIdBypassKind.forecast:
      runForecastOverseasTonnageExpectation(scenario.forecastPins!);
    case ExtractionByIdBypassKind.capacity:
      runTradeCargoCapacityExtractionExpectation(scenario.capacityPins!);
    case ExtractionByIdBypassKind.emptyMaps:
      runComputeExtractionTotalsEmptyMapsExpectation();
  }
}
// dart format on

void main() {
  runLabeledScenarioGroup(
    'overseasShippedTonnageFromExtractionTotals',
    overseasShippedTonnageScenarios(),
    runOverseasShippedTonnageScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'tradeCargoCapacityForGreatPower',
    tradeCargoCapacityForGreatPowerScenarios(),
    runTradeCargoCapacityForGreatPowerScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'extractionById bypass (Refs #3517 Cluster 4)',
    extractionByIdBypassScenarios(),
    runExtractionByIdBypassScenario,
    labelOf: (s) => s.label,
  );
}
