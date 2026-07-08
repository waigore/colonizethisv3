// Table-driven trade cargo capacity scenarios (Refs #3939 phase 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'scenario_runner.dart';

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

void runOverseasShippedTonnageScenario(OverseasShippedTonnageScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [overseasShippedTonnageFromExtractionTotals].
List<OverseasShippedTonnageScenario> overseasShippedTonnageScenarios() => [
      OverseasShippedTonnageScenario(
        label: 'sums units committed by allocateOverseasToStockpile',
        run: () {
          expect(
            overseasShippedTonnageFromExtractionTotals(const {
              'grain': 20,
            }, homeFleetCargoHolds: 12),
            12,
          );
        },
      ),
      OverseasShippedTonnageScenario(
        label: 'returns 0 when no overseas totals or zero holds',
        run: () {
          expect(
            overseasShippedTonnageFromExtractionTotals(
              const {},
              homeFleetCargoHolds: 3,
            ),
            0,
          );
          expect(
            overseasShippedTonnageFromExtractionTotals(const {
              'grain': 5,
            }, homeFleetCargoHolds: 0),
            0,
          );
        },
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
      TradeCargoCapacityForGreatPowerScenario(
        label: 'returns full home fleet when tile maps are empty',
        run: () {
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
        },
      ),
    ];

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

const MapTopology _emptyTopologyForTradeCargo =
    MapTopology(nodes: [], edges: []);

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
      ExtractionByIdBypassScenario(
        label:
            'forecastOverseasShippedTonnageForPlayer reads provided extractionById '
            'map and does not depend on tile extraction',
        run: () {
          final game = _gameWithGp('gp1');
          final shipped = forecastOverseasShippedTonnageForPlayer(
            game: game,
            playerId: 'gp1',
            tileMapByRegion: _nonEmptyTileMapForTradeCargo,
            topology: _emptyTopologyForTradeCargo,
            extractionById: const {
              'gp1': ExtractionTotals(overseas: {'grain': 10}),
            },
          );
          expect(
            shipped,
            overseasShippedTonnageFromExtractionTotals(const {
              'grain': 10,
            }, homeFleetCargoHolds: cargoHoldsForHomeFleet(game, 'gp1')),
          );
          expect(shipped, 10);
        },
        refs: '#3517',
      ),
      ExtractionByIdBypassScenario(
        label:
            'forecastOverseasShippedTonnageForPlayer returns 0 when the provided '
            'extractionById has no entry for the player',
        run: () {
          final game = _gameWithGp('gp1');
          expect(
            forecastOverseasShippedTonnageForPlayer(
              game: game,
              playerId: 'gp1',
              tileMapByRegion: _nonEmptyTileMapForTradeCargo,
              topology: _emptyTopologyForTradeCargo,
              extractionById: const {
                'gp2': ExtractionTotals(overseas: {'grain': 10}),
              },
            ),
            0,
          );
        },
        refs: '#3517',
      ),
      ExtractionByIdBypassScenario(
        label:
            'tradeCargoCapacityForGreatPower subtracts map-derived overseas tonnage '
            'from home-fleet holds',
        run: () {
          final game = _gameWithGp('gp1');
          final holds = cargoHoldsForHomeFleet(game, 'gp1');
          final capacity = tradeCargoCapacityForGreatPower(
            game: game,
            playerId: 'gp1',
            tileMapByRegion: _nonEmptyTileMapForTradeCargo,
            topology: _emptyTopologyForTradeCargo,
            extractionById: const {
              'gp1': ExtractionTotals(overseas: {'grain': 4}),
            },
          );
          expect(capacity, holds - 4);
        },
        refs: '#3517',
      ),
      ExtractionByIdBypassScenario(
        label: 'computeExtractionTotalsForTradeForecast returns empty for empty '
            'tile maps',
        run: () {
          final game = _gameWithGp('gp1');
          expect(
            computeExtractionTotalsForTradeForecast(
              game: game,
              tileMapByRegion: const {},
              topology: _emptyTopologyForTradeCargo,
            ),
            isEmpty,
          );
        },
        refs: '#3517',
      ),
    ];
