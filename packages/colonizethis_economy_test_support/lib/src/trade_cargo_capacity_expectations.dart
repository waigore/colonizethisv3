// dart format off
// Compact trade cargo capacity assertions (Refs #3939 phase 3 slice 35).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'trade_cargo_capacity_scenarios.dart';

/// One overseas-tonnage assertion case.
typedef OverseasTonnageCase = ({Map<String, int> overseasTotals, int homeFleetCargoHolds, int expected});

/// Pins for [overseasShippedTonnageFromExtractionTotals] rows.
typedef OverseasShippedTonnagePins = ({List<OverseasTonnageCase> cases});

void runOverseasShippedTonnageExpectation(OverseasShippedTonnagePins pins) {
  for (final caseRow in pins.cases) {
    expect(overseasShippedTonnageFromExtractionTotals(caseRow.overseasTotals, homeFleetCargoHolds: caseRow.homeFleetCargoHolds), caseRow.expected);
  }
}

OverseasShippedTonnageScenario overseasShippedTonnageScenario({required String label, required OverseasShippedTonnagePins pins}) => (label: label, run: () => runOverseasShippedTonnageExpectation(pins), refs: null);

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

TradeCargoCapacityForGreatPowerScenario tradeCargoCapacityEmptyTileMapsScenario({required String label}) => (label: label, run: runTradeCargoCapacityEmptyTileMapsExpectation, refs: null);

Game _gameWithGp(String id) => minimalGpGame(playerId: id);

/// A non-empty tile map clears the `tileMapByRegion.isEmpty` guard without
/// contributing extraction on the pre-computed-map path.
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

/// Pins for forecast-overseas-tonnage rows.
typedef ForecastOverseasTonnagePins = ({String playerId, Map<String, ExtractionTotals> extractionById, Map<String, int>? deriveOverseasTotals, int? expectedExact});

void runForecastOverseasTonnageExpectation(ForecastOverseasTonnagePins pins) {
  final game = _gameWithGp(pins.playerId);
  final shipped = forecastOverseasShippedTonnageForPlayer(game: game, playerId: pins.playerId, tileMapByRegion: _nonEmptyTileMapForTradeCargo, topology: _emptyTopologyForTradeCargo, extractionById: pins.extractionById);
  if (pins.deriveOverseasTotals != null) {
    expect(shipped, overseasShippedTonnageFromExtractionTotals(pins.deriveOverseasTotals!, homeFleetCargoHolds: cargoHoldsForHomeFleet(game, pins.playerId)));
  }
  if (pins.expectedExact != null) {
    expect(shipped, pins.expectedExact);
  }
}

ExtractionByIdBypassScenario forecastOverseasTonnageScenario({required String label, required ForecastOverseasTonnagePins pins, String? refs}) => (label: label, run: () => runForecastOverseasTonnageExpectation(pins), refs: refs);

/// Pins for trade-cargo capacity with pre-computed extraction rows.
typedef TradeCargoCapacityExtractionPins = ({String playerId, Map<String, ExtractionTotals> extractionById, int overseasTonnageSubtracted});

void runTradeCargoCapacityExtractionExpectation(TradeCargoCapacityExtractionPins pins) {
  final game = _gameWithGp(pins.playerId);
  final holds = cargoHoldsForHomeFleet(game, pins.playerId);
  final capacity = tradeCargoCapacityForGreatPower(game: game, playerId: pins.playerId, tileMapByRegion: _nonEmptyTileMapForTradeCargo, topology: _emptyTopologyForTradeCargo, extractionById: pins.extractionById);
  expect(capacity, holds - pins.overseasTonnageSubtracted);
}

ExtractionByIdBypassScenario tradeCargoCapacityExtractionScenario({required String label, required TradeCargoCapacityExtractionPins pins, String? refs}) => (label: label, run: () => runTradeCargoCapacityExtractionExpectation(pins), refs: refs);

void runComputeExtractionTotalsEmptyMapsExpectation() {
  final game = _gameWithGp('gp1');
  expect(computeExtractionTotalsForTradeForecast(game: game, tileMapByRegion: const {}, topology: _emptyTopologyForTradeCargo), isEmpty);
}

ExtractionByIdBypassScenario computeExtractionTotalsEmptyMapsScenario({required String label, String? refs}) => (label: label, run: runComputeExtractionTotalsEmptyMapsExpectation, refs: refs);
// dart format on
