// Part 2: negative / boundary / multi-faction tests for
// `computeNonGreatPowerExtraction` — Issue #2991 C2.
//
// SPEC-AC happy paths are pinned in `non_gp_extraction_part1_test.dart`. This
// suite pins the contract's behaviour for:
//
//   * empty inputs (factions, tile maps, connectivity);
//   * factions without capital metadata (silently skipped, no throw);
//   * tiles whose effective yield is zero after the transport / town-dev
//     branches (suppressed from output, not emitted as `commodity: 0`);
//   * multi-faction runs (minor + tribe, distinct keys in output);
//   * aggregation across multiple connected tiles of the same commodity.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/src/world/connectivity_resolver.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'non_gp_extraction_test_support.dart';

void main() {
  group('computeNonGreatPowerExtraction (boundary + multi-faction)', () {
    test(
      'empty minors and tribes lists yield an empty result and skip lookups',
      () {
        final game = gameForNonGpExtractionTest(provinces: const []);
        final result = computeNonGreatPowerExtraction(
          game: game,
          tileMapByRegion: const <String, TileMapResult>{},
          connectivityByFactionId: const <String, ConnectivityResult>{},
        );
        expect(result, isEmpty);
      },
    );

    test(
      'empty tileMapByRegion short-circuits even when minors/tribes present',
      () {
        final game = gameForNonGpExtractionTest(
          provinces: [
            capitalProvinceForNonGpExtractionTest(provinceId: 'oldWorld|m1'),
          ],
          minorNations: [testMinor()],
        );
        final result = computeNonGreatPowerExtraction(
          game: game,
          tileMapByRegion: const <String, TileMapResult>{},
          connectivityByFactionId: {
            'm1': ConnectivityResult(connected: {'oldWorld|m1|1|0'}),
          },
        );
        expect(result, isEmpty);
      },
    );

    test('minor without capitalProvinceId or capitalTile is skipped silently '
        '(no throw, no entry in output)', () {
      final game = gameForNonGpExtractionTest(
        provinces: const [],
        minorNations: const [
          // No capitalProvinceId.
          MinorNation(id: 'm1'),
          // Only provinceId, no capitalTile (so no regionId either).
          MinorNation(id: 'm2', capitalProvinceId: 'oldWorld|m2'),
        ],
      );
      final result = computeNonGreatPowerExtraction(
        game: game,
        tileMapByRegion: {
          'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
            provinceId: 'oldWorld|m2',
            width: 1,
            height: 1,
            resources: const [
              [Resource.grain],
            ],
          ),
        },
        connectivityByFactionId: {
          'm1': ConnectivityResult(connected: {'oldWorld|m1|0|0'}),
          'm2': ConnectivityResult(connected: {'oldWorld|m2|0|0'}),
        },
      );
      expect(result, isEmpty);
    });

    test(
      'minor with capital but no connectivity entry in the input is skipped',
      () {
        const provinceId = 'oldWorld|m1';
        final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
          provinceId: provinceId,
          width: 1,
          height: 1,
          resources: const [
            [Resource.grain],
          ],
        );
        final tileState = TileMapState()
            .setImprovement('oldWorld|m1|0|0', 1)
            .setRoadLevel('oldWorld|m1|0|0', 1);
        final game = gameForNonGpExtractionTest(
          provinces: [
            capitalProvinceForNonGpExtractionTest(provinceId: provinceId),
          ],
          tileState: tileState,
          minorNations: [testMinor()],
        );

        final result = computeNonGreatPowerExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          connectivityByFactionId: const <String, ConnectivityResult>{},
        );

        expect(result, isEmpty);
      },
    );

    test('tile with road level 0 (no transport path) yields 0 even when listed '
        'as connected and improved', () {
      // Path transport cap defaults to the tile's own transport level when
      // not supplied; with road level 0, pathCap is 0, and effective yield
      // is min(prod=1, pathCap=0) = 0.
      const provinceId = 'oldWorld|m1';
      final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: provinceId,
        width: 2,
        height: 2,
        resources: [
          [null, Resource.timber],
          [null, null],
        ],
      );
      final tileState = TileMapState().setImprovement('oldWorld|m1|1|0', 1);
      final game = gameForNonGpExtractionTest(
        provinces: [
          capitalProvinceForNonGpExtractionTest(provinceId: provinceId),
        ],
        tileState: tileState,
        minorNations: [testMinor()],
      );

      final result = computeNonGreatPowerExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityByFactionId: {
          'm1': ConnectivityResult(connected: {'oldWorld|m1|1|0'}),
        },
      );

      expect(result, isEmpty);
    });

    test('minor and tribe in the same Game both produce per-faction totals '
        'keyed by their ids', () {
      const minorProv = 'oldWorld|m1';
      const tribeProv = 'newWorld|t1';
      final owMap = tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: minorProv,
        width: 1,
        height: 1,
        resources: const [
          [Resource.timber],
        ],
      );
      final nwMap = tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: tribeProv,
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
          capitalProvinceForNonGpExtractionTest(provinceId: minorProv),
        ],
        newWorldProvinces: [
          Province(
            id: tribeProv,
            regionId: 'newWorld',
            ownerId: 't1',
            townDevelopmentLevel: 1,
          ),
        ],
        tileState: tileState,
        minorNations: [testMinor()],
        tribes: [testTribe()],
      );

      final result = computeNonGreatPowerExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        connectivityByFactionId: {
          'm1': ConnectivityResult(connected: {'oldWorld|m1|0|0'}),
          't1': ConnectivityResult(connected: {'newWorld|t1|0|0'}),
        },
      );

      expect(result.keys, unorderedEquals(<String>['m1', 't1']));
      expect(result['m1'], equals(<CommodityId, int>{'timber': 1}));
      expect(result['t1'], equals(<CommodityId, int>{'furs': 1}));
    });

    test(
      'aggregates multiple connected non-mineral tiles of the same commodity '
      'into a single per-faction total',
      () {
        const provinceId = 'oldWorld|m1';
        final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
          provinceId: provinceId,
          width: 3,
          height: 1,
          resources: const [
            [Resource.grain, Resource.grain, Resource.timber],
          ],
        );
        final tileState = TileMapState()
            .setImprovement('oldWorld|m1|0|0', 1)
            .setRoadLevel('oldWorld|m1|0|0', 1)
            .setImprovement('oldWorld|m1|1|0', 1)
            .setRoadLevel('oldWorld|m1|1|0', 1)
            .setImprovement('oldWorld|m1|2|0', 1)
            .setRoadLevel('oldWorld|m1|2|0', 1);
        final game = gameForNonGpExtractionTest(
          provinces: [
            capitalProvinceForNonGpExtractionTest(provinceId: provinceId),
          ],
          tileState: tileState,
          minorNations: [testMinor()],
        );
        final result = computeNonGreatPowerExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          connectivityByFactionId: {
            'm1': ConnectivityResult(
              connected: {
                'oldWorld|m1|0|0',
                'oldWorld|m1|1|0',
                'oldWorld|m1|2|0',
              },
            ),
          },
        );
        expect(
          result['m1'],
          equals(<CommodityId, int>{'grain': 2, 'timber': 1}),
        );
      },
    );

    test('tile in a province whose town development level is 0 yields 0 '
        'in the capital province (town dev cap is a hard floor)', () {
      const provinceId = 'oldWorld|m1';
      final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: provinceId,
        width: 2,
        height: 1,
        resources: const [
          [null, Resource.timber],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|m1|1|0', 1)
          .setRoadLevel('oldWorld|m1|1|0', 1);
      final game = gameForNonGpExtractionTest(
        provinces: [
          // Town dev = 0 caps capital-province effective yield to 0.
          capitalProvinceForNonGpExtractionTest(
            provinceId: provinceId,
            townDev: 0,
          ),
        ],
        tileState: tileState,
        minorNations: [testMinor()],
      );
      final result = computeNonGreatPowerExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityByFactionId: {
          'm1': ConnectivityResult(connected: {'oldWorld|m1|1|0'}),
        },
      );
      expect(result, isEmpty);
    });
  });
}
