import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/ai_api.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('overseasShippedTonnageFromExtractionTotals', () {
    test('sums units committed by allocateOverseasToStockpile', () {
      expect(
        overseasShippedTonnageFromExtractionTotals(const {
          'grain': 20,
        }, homeFleetCargoHolds: 12),
        12,
      );
    });

    test('returns 0 when no overseas totals or zero holds', () {
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
    });
  });

  group('tradeCargoCapacityForGreatPower', () {
    test('returns full home fleet when tile maps are empty', () {
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
    });
  });

  // Refs #3517 Cluster 4: when a pre-computed extraction map is threaded in,
  // the forecast/capacity helpers read it directly instead of re-running the
  // O(players × connected-tiles) `computeExtraction` scan.
  group('extractionById bypass (Refs #3517 Cluster 4)', () {
    // Player with no home fleet → cargo holds fall back to
    // `defaultCargoHoldsStub` (24).
    Game gameWithGp(String id) => minimalGpGame(playerId: id);

    // A non-empty tile map clears the `tileMapByRegion.isEmpty` guard without
    // contributing any extraction (its content is unused on the
    // pre-computed-map path because `computeExtraction` is never called).
    final nonEmptyTileMap = {
      'r1': TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['p1'],
        ],
      ),
    };
    const topology = MapTopology(nodes: [], edges: []);

    test(
      'forecastOverseasShippedTonnageForPlayer reads provided extractionById '
      'map and does not depend on tile extraction',
      () {
        final game = gameWithGp('gp1');
        final shipped = forecastOverseasShippedTonnageForPlayer(
          game: game,
          playerId: 'gp1',
          tileMapByRegion: nonEmptyTileMap,
          topology: topology,
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
    );

    test('forecastOverseasShippedTonnageForPlayer returns 0 when the provided '
        'extractionById has no entry for the player', () {
      final game = gameWithGp('gp1');
      expect(
        forecastOverseasShippedTonnageForPlayer(
          game: game,
          playerId: 'gp1',
          tileMapByRegion: nonEmptyTileMap,
          topology: topology,
          extractionById: const {
            'gp2': ExtractionTotals(overseas: {'grain': 10}),
          },
        ),
        0,
      );
    });

    test(
      'tradeCargoCapacityForGreatPower subtracts map-derived overseas tonnage '
      'from home-fleet holds',
      () {
        final game = gameWithGp('gp1');
        final holds = cargoHoldsForHomeFleet(game, 'gp1');
        final capacity = tradeCargoCapacityForGreatPower(
          game: game,
          playerId: 'gp1',
          tileMapByRegion: nonEmptyTileMap,
          topology: topology,
          extractionById: const {
            'gp1': ExtractionTotals(overseas: {'grain': 4}),
          },
        );
        expect(capacity, holds - 4);
      },
    );

    test('computeExtractionTotalsForTradeForecast returns empty for empty '
        'tile maps', () {
      final game = gameWithGp('gp1');
      expect(
        computeExtractionTotalsForTradeForecast(
          game: game,
          tileMapByRegion: const {},
          topology: topology,
        ),
        isEmpty,
      );
    });
  });
}
