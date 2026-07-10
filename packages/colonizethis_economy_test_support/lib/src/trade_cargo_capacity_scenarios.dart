// Table-driven trade cargo capacity scenarios (Refs #3939 phase 3 slice 35).

import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'scenario_runner.dart';
import 'trade_cargo_capacity_expectations.dart';

/// One row in [overseasShippedTonnageScenarios].
class OverseasShippedTonnageScenario implements RefsScenario {
  const OverseasShippedTonnageScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOverseasShippedTonnageScenario(
  OverseasShippedTonnageScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [overseasShippedTonnageFromExtractionTotals].
List<OverseasShippedTonnageScenario> overseasShippedTonnageScenarios() => [
  overseasShippedTonnageScenario(
    label: 'sums units committed by allocateOverseasToStockpile',
    pins: (
      cases: [
        (overseasTotals: {'grain': 20}, homeFleetCargoHolds: 12, expected: 12),
      ],
    ),
  ),
  overseasShippedTonnageScenario(
    label: 'returns 0 when no overseas totals or zero holds',
    pins: (
      cases: [
        (overseasTotals: <String, int>{}, homeFleetCargoHolds: 3, expected: 0),
        (overseasTotals: {'grain': 5}, homeFleetCargoHolds: 0, expected: 0),
      ],
    ),
  ),
];

/// One row in [tradeCargoCapacityForGreatPowerScenarios].
class TradeCargoCapacityForGreatPowerScenario implements RefsScenario {
  const TradeCargoCapacityForGreatPowerScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runTradeCargoCapacityForGreatPowerScenario(
  TradeCargoCapacityForGreatPowerScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [tradeCargoCapacityForGreatPower] (empty tile maps).
List<TradeCargoCapacityForGreatPowerScenario>
tradeCargoCapacityForGreatPowerScenarios() => [
  tradeCargoCapacityEmptyTileMapsScenario(
    label: 'returns full home fleet when tile maps are empty',
  ),
];

/// One row in [extractionByIdBypassScenarios].
class ExtractionByIdBypassScenario implements RefsScenario {
  const ExtractionByIdBypassScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runExtractionByIdBypassScenario(ExtractionByIdBypassScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for extractionById bypass (Refs #3517 Cluster 4).
List<ExtractionByIdBypassScenario> extractionByIdBypassScenarios() => [
  forecastOverseasTonnageScenario(
    label:
        'forecastOverseasShippedTonnageForPlayer reads provided extractionById '
        'map and does not depend on tile extraction',
    pins: (
      playerId: 'gp1',
      extractionById: const {
        'gp1': ExtractionTotals(overseas: {'grain': 10}),
      },
      deriveOverseasTotals: {'grain': 10},
      expectedExact: 10,
    ),
    refs: '#3517',
  ),
  forecastOverseasTonnageScenario(
    label:
        'forecastOverseasShippedTonnageForPlayer returns 0 when the provided '
        'extractionById has no entry for the player',
    pins: (
      playerId: 'gp1',
      extractionById: const {
        'gp2': ExtractionTotals(overseas: {'grain': 10}),
      },
      deriveOverseasTotals: null,
      expectedExact: 0,
    ),
    refs: '#3517',
  ),
  tradeCargoCapacityExtractionScenario(
    label:
        'tradeCargoCapacityForGreatPower subtracts map-derived overseas tonnage '
        'from home-fleet holds',
    pins: (
      playerId: 'gp1',
      extractionById: const {
        'gp1': ExtractionTotals(overseas: {'grain': 4}),
      },
      overseasTonnageSubtracted: 4,
    ),
    refs: '#3517',
  ),
  computeExtractionTotalsEmptyMapsScenario(
    label:
        'computeExtractionTotalsForTradeForecast returns empty for empty '
        'tile maps',
    refs: '#3517',
  ),
];
