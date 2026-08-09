// dart format off
// Table-driven trade cargo capacity scenarios (Refs #3939 phase 3 slice 35, #3979).
import 'package:colonizethis_economy/colonizethis_economy.dart';

/// One overseas-tonnage assertion case.
typedef OverseasTonnageCase = ({Map<String, int> overseasTotals, int homeFleetCargoHolds, int expected});

/// Pins for [overseasShippedTonnageFromExtractionTotals] rows.
typedef OverseasShippedTonnagePins = ({List<OverseasTonnageCase> cases});

OverseasShippedTonnageScenario overseasShippedTonnageScenario({required String label, required OverseasShippedTonnagePins pins}) => (label: label, pins: pins, refs: null);

/// One row in [overseasShippedTonnageScenarios] (Refs #3979).
typedef OverseasShippedTonnageScenario = ({String label, OverseasShippedTonnagePins pins, String? refs});

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

/// Discriminator for GP trade-cargo capacity rows (Refs #3979).
enum TradeCargoCapacityGpTarget { emptyTileMaps }

TradeCargoCapacityForGreatPowerScenario tradeCargoCapacityEmptyTileMapsScenario({required String label}) => (label: label, target: TradeCargoCapacityGpTarget.emptyTileMaps, refs: null);

/// One row in [tradeCargoCapacityForGreatPowerScenarios] (Refs #3979).
typedef TradeCargoCapacityForGreatPowerScenario = ({String label, TradeCargoCapacityGpTarget target, String? refs});

/// Canonical scenarios for [tradeCargoCapacityForGreatPower] (empty tile maps).
List<TradeCargoCapacityForGreatPowerScenario> tradeCargoCapacityForGreatPowerScenarios() => [tradeCargoCapacityEmptyTileMapsScenario(label: 'returns full home fleet when tile maps are empty')];

/// Discriminator for extractionById bypass rows (Refs #3979).
enum ExtractionByIdBypassKind { forecast, capacity, emptyMaps }

/// Pins for forecast-overseas-tonnage rows.
typedef ForecastOverseasTonnagePins = ({String playerId, Map<String, ExtractionTotals> extractionById, Map<String, int>? deriveOverseasTotals, int? expectedExact});

ExtractionByIdBypassScenario forecastOverseasTonnageScenario({required String label, required ForecastOverseasTonnagePins pins, String? refs}) => (label: label, kind: ExtractionByIdBypassKind.forecast, forecastPins: pins, capacityPins: null, refs: refs);

/// Pins for trade-cargo capacity with pre-computed extraction rows.
typedef TradeCargoCapacityExtractionPins = ({String playerId, Map<String, ExtractionTotals> extractionById, int overseasTonnageSubtracted});

ExtractionByIdBypassScenario tradeCargoCapacityExtractionScenario({required String label, required TradeCargoCapacityExtractionPins pins, String? refs}) => (label: label, kind: ExtractionByIdBypassKind.capacity, forecastPins: null, capacityPins: pins, refs: refs);

ExtractionByIdBypassScenario computeExtractionTotalsEmptyMapsScenario({required String label, String? refs}) => (label: label, kind: ExtractionByIdBypassKind.emptyMaps, forecastPins: null, capacityPins: null, refs: refs);

/// One row in [extractionByIdBypassScenarios] (Refs #3979).
typedef ExtractionByIdBypassScenario = ({
  String label,
  ExtractionByIdBypassKind kind,
  ForecastOverseasTonnagePins? forecastPins,
  TradeCargoCapacityExtractionPins? capacityPins,
  String? refs,
});

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
// dart format on
