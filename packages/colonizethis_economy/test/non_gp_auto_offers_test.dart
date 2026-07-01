// SPEC-AC tests for `computeNonGreatPowerAutoOffers` — Issue #2991 C4.
//
// Anchors `SPEC/program/world-market-resolution.md` § Step A Gather (Step
// A.2) and `SPEC/game/world-market.md` § Minor and tribe auto-sell:
//
//   - One `TradeOrder(offer)` per contributing tile (per-tile attribution
//     so FRR #2992 D2/D4 can credit the owning Great Power).
//   - `priority == 1`, `originTileKey == tileKey`, `type == offer`.
//   - Riches commodities (`spices`, `silver`, `gold`, `gems`, `diamonds`)
//     are excluded from auto-offers per Requirement 11 (riches do not
//     trade — they auto-convert to treasury via the riches-to-treasury
//     phase, not the World Market).
//   - Empty fixtures (no minors/tribes, no tile maps, no connectivity)
//     produce no auto-offers (matches the legacy direct-handler test
//     contract for the World Market phase).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/src/world/connectivity_resolver.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeNonGreatPowerAutoOffers (SPEC AC: minor/tribe auto-sell)', () {
    test('empty when no minors and no tribes are configured', () {
      final game = gameForNonGpExtractionTest(provinces: const []);
      final result = computeNonGreatPowerAutoOffers(
        game: game,
        tileMapByRegion: const {},
        connectivityByFactionId: const {},
      );
      expect(result, isEmpty);
    });

    test('empty when tileMapByRegion is empty', () {
      const provinceId = 'oldWorld|m1';
      final game = gameForNonGpExtractionTest(
        provinces: [
          capitalProvinceForNonGpExtractionTest(provinceId: provinceId),
        ],
        minorNations: [testMinor()],
      );
      final result = computeNonGreatPowerAutoOffers(
        game: game,
        tileMapByRegion: const {},
        connectivityByFactionId: const {
          'm1': ConnectivityResult(connected: <String>{'oldWorld|m1|0|0'}),
        },
      );
      expect(result, isEmpty);
    });

    test(
      'emits one priority-1 offer per non-riches tile with originTileKey set',
      () {
        const provinceId = 'oldWorld|m1';
        final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
          provinceId: provinceId,
          width: 2,
          height: 1,
          resources: const [
            [Resource.timber, Resource.grain],
          ],
        );
        final tileState = TileMapState()
            .setImprovement('oldWorld|m1|0|0', 1)
            .setRoadLevel('oldWorld|m1|0|0', 1)
            .setImprovement('oldWorld|m1|1|0', 1)
            .setRoadLevel('oldWorld|m1|1|0', 1);
        final game = gameForNonGpExtractionTest(
          provinces: [
            capitalProvinceForNonGpExtractionTest(provinceId: provinceId),
          ],
          tileState: tileState,
          minorNations: [testMinor()],
        );

        final result = computeNonGreatPowerAutoOffers(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          connectivityByFactionId: const {
            'm1': ConnectivityResult(
              connected: <String>{'oldWorld|m1|0|0', 'oldWorld|m1|1|0'},
            ),
          },
        );

        expect(result.keys, equals(<String>{'m1'}));
        final orders = result['m1']!;
        expect(orders, hasLength(2));
        for (final order in orders) {
          expect(order.type, equals(TradeOrderType.offer));
          expect(order.priority, equals(1));
          expect(order.quantity, equals(1));
          expect(order.originTileKey, isNotNull);
          expect(order.isFtp, isFalse);
        }
        // Tiles are emitted in ascending tileKey order so identical
        // fixtures produce identical outputs across runs.
        expect(
          orders.map((o) => o.originTileKey).toList(),
          equals(<String>['oldWorld|m1|0|0', 'oldWorld|m1|1|0']),
        );
        expect(
          orders.map((o) => o.commodityId).toList(),
          equals(<CommodityId>['timber', 'grain']),
        );
      },
    );

    test('aggregates minor and tribe offers in the same result map', () {
      const minorProvinceId = 'oldWorld|m1';
      const tribeProvinceId = 'newWorld|t1';
      final owMap = tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: minorProvinceId,
        width: 1,
        height: 1,
        resources: const [
          [Resource.timber],
        ],
      );
      final nwMap = tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: tribeProvinceId,
        width: 1,
        height: 1,
        resources: const [
          [Resource.furs],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|m1|0|0', 1)
          .setRoadLevel('oldWorld|m1|0|0', 1)
          .setImprovement('newWorld|t1|0|0', 1)
          .setRoadLevel('newWorld|t1|0|0', 1);
      final game = gameForNonGpExtractionTest(
        provinces: [
          capitalProvinceForNonGpExtractionTest(provinceId: minorProvinceId),
        ],
        newWorldProvinces: [
          capitalProvinceForNonGpExtractionTest(provinceId: tribeProvinceId),
        ],
        tileState: tileState,
        minorNations: [testMinor()],
        tribes: [testTribe()],
      );

      final result = computeNonGreatPowerAutoOffers(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        connectivityByFactionId: const {
          'm1': ConnectivityResult(connected: <String>{'oldWorld|m1|0|0'}),
          't1': ConnectivityResult(connected: <String>{'newWorld|t1|0|0'}),
        },
      );

      expect(result.keys, unorderedEquals(<String>['m1', 't1']));
      expect(result['m1'], hasLength(1));
      expect(result['t1'], hasLength(1));
      expect(result['m1']!.first.commodityId, equals('timber'));
      expect(result['t1']!.first.commodityId, equals('furs'));
    });

    test('excludes riches commodities (spices) per Requirement 11 — '
        'riches do not trade on the world market', () {
      const provinceId = 'oldWorld|m1';
      final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: provinceId,
        width: 2,
        height: 1,
        resources: const [
          [Resource.spices, Resource.grain],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|m1|0|0', 1)
          .setRoadLevel('oldWorld|m1|0|0', 1)
          .setImprovement('oldWorld|m1|1|0', 1)
          .setRoadLevel('oldWorld|m1|1|0', 1);
      final game = gameForNonGpExtractionTest(
        provinces: [
          capitalProvinceForNonGpExtractionTest(provinceId: provinceId),
        ],
        tileState: tileState,
        minorNations: [testMinor()],
      );

      final result = computeNonGreatPowerAutoOffers(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityByFactionId: const {
          'm1': ConnectivityResult(
            connected: <String>{'oldWorld|m1|0|0', 'oldWorld|m1|1|0'},
          ),
        },
      );

      expect(result.keys, equals(<String>{'m1'}));
      final orders = result['m1']!;
      expect(orders, hasLength(1));
      expect(orders.first.commodityId, equals('grain'));
      expect(orders.first.originTileKey, equals('oldWorld|m1|1|0'));
      for (final order in orders) {
        expect(order.commodityId, isNot(equals('spices')));
      }
    });

    test(
      'minerals stay excluded (covered by computeNonGreatPowerExtraction '
      'mineral filter) — no offer emitted for an iron tile even if developed',
      () {
        const provinceId = 'oldWorld|m1';
        final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
          provinceId: provinceId,
          width: 2,
          height: 1,
          resources: const [
            [Resource.iron, Resource.grain],
          ],
        );
        final tileState = TileMapState()
            .setImprovement('oldWorld|m1|0|0', 1)
            .setRoadLevel('oldWorld|m1|0|0', 1)
            .setImprovement('oldWorld|m1|1|0', 1)
            .setRoadLevel('oldWorld|m1|1|0', 1);
        final game = gameForNonGpExtractionTest(
          provinces: [
            capitalProvinceForNonGpExtractionTest(provinceId: provinceId),
          ],
          tileState: tileState,
          minorNations: [testMinor()],
        );

        final result = computeNonGreatPowerAutoOffers(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          connectivityByFactionId: const {
            'm1': ConnectivityResult(
              connected: <String>{'oldWorld|m1|0|0', 'oldWorld|m1|1|0'},
            ),
          },
        );

        expect(result['m1'], hasLength(1));
        expect(result['m1']!.first.commodityId, equals('grain'));
      },
    );

    test(
      'factions with no connectivity entry do not appear in the auto-offer map',
      () {
        const provinceId = 'oldWorld|m1';
        final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
          provinceId: provinceId,
          width: 1,
          height: 1,
          resources: const [
            [Resource.timber],
          ],
        );
        final game = gameForNonGpExtractionTest(
          provinces: [
            capitalProvinceForNonGpExtractionTest(provinceId: provinceId),
          ],
          tileState: TileMapState().setImprovement('oldWorld|m1|0|0', 1),
          minorNations: [testMinor()],
        );

        final result = computeNonGreatPowerAutoOffers(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          connectivityByFactionId: const {},
        );

        expect(result, isEmpty);
      },
    );
  });
}
