// Part 1: SPEC-AC tests for `computeNonGreatPowerExtraction` — Issue #2991 C2.
//
// Anchors the three SPEC contracts in
// `SPEC/game/extraction-and-improvements.md` § Non-Great-Power extraction:
//
//   1. Tech cap is `defaultExtractionCap = 1` for every resource — non-GP
//      improvement level is clamped to 1 before transport/town caps apply.
//   2. Mineral resources are unconditionally excluded (minors/tribes never
//      prospect; the prospecting gate's "(b) prospected" arm can never fire).
//   3. Capital-tile grain bonus is Great-Power-only (not applied to non-GP
//      totals).
//
// Negative/boundary and aggregation cases live in
// `non_gp_extraction_part2_test.dart`. Helpers are in
// `non_gp_extraction_test_support.dart` so each part stays inside the
// `repo.logic_test_file_size` 400-line budget.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'non_gp_extraction_test_support.dart';

void main() {
  group('computeNonGreatPowerExtraction (SPEC ACs)', () {
    test('minor with non-mineral connected tile produces 1 unit at imp=1', () {
      const provinceId = 'oldWorld|m1';
      final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
        provinceId: provinceId,
        width: 2,
        height: 2,
        resources: [
          [null, Resource.grain],
          [null, null],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|m1|1|0', 1)
          .setRoadLevel('oldWorld|m1|1|0', 1);
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

      expect(result, contains('m1'));
      expect(result['m1'], equals(<CommodityId, int>{'grain': 1}));
    });

    test(
      'tech cap clamps higher-improvement non-mineral tile to 1 unit '
      '(SPEC AC: defaultExtractionCap = 1, applied before transport/town)',
      () {
        const provinceId = 'oldWorld|m1';
        final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
          provinceId: provinceId,
          width: 2,
          height: 2,
          resources: [
            [null, Resource.grain],
            [null, null],
          ],
        );
        // GP-side this would yield 4 (improvement=4, transport=4, town
        // development=4). Non-GP tech cap of 1 clamps production to 1, so the
        // effective yield is 1 regardless of how high the tile is improved.
        final tileState = TileMapState()
            .setImprovement('oldWorld|m1|1|0', 4)
            .setRoadLevel('oldWorld|m1|1|0', 4);
        final game = gameForNonGpExtractionTest(
          provinces: [
            capitalProvinceForNonGpExtractionTest(
              provinceId: provinceId,
              townDev: 4,
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

        expect(result['m1'], equals(<CommodityId, int>{'grain': 1}));
      },
    );

    test(
      'mineral resources on non-GP tiles are unconditionally excluded '
      '(SPEC AC: tribes/minors never prospect)',
      () {
        const provinceId = 'newWorld|t1';
        final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
          provinceId: provinceId,
          width: 2,
          height: 2,
          resources: [
            [null, Resource.iron],
            [null, Resource.grain],
          ],
        );
        // Even at the maximum legal improvement/transport the iron tile is
        // dropped: minors and tribes have no Explorers and so cannot satisfy
        // the prospecting gate. The adjacent grain tile is unaffected.
        final tileState = TileMapState()
            .setImprovement('newWorld|t1|1|0', 4)
            .setRoadLevel('newWorld|t1|1|0', 4)
            .setImprovement('newWorld|t1|1|1', 1)
            .setRoadLevel('newWorld|t1|1|1', 1);
        final game = gameForNonGpExtractionTest(
          provinces: const [],
          newWorldProvinces: [
            Province(
              id: provinceId,
              regionId: 'newWorld',
              ownerId: 't1',
              townDevelopmentLevel: 1,
            ),
          ],
          tileState: tileState,
          tribes: [testTribe()],
        );

        final result = computeNonGreatPowerExtraction(
          game: game,
          tileMapByRegion: {'newWorld': tileMap},
          connectivityByFactionId: {
            't1': ConnectivityResult(
              connected: {'newWorld|t1|1|0', 'newWorld|t1|1|1'},
            ),
          },
        );

        expect(result['t1'], equals(<CommodityId, int>{'grain': 1}));
        expect(result['t1'], isNot(contains('iron')));
      },
    );

    test(
      'capital-tile grain bonus is NOT applied to non-GP totals '
      '(SPEC AC: Great-Power-only rule)',
      () {
        // No connected tiles for the minor, just a capital tile + a
        // capital-tile grain bonus of 5 in the Game config. GP-equivalent
        // factions would receive +5 grain from the bonus per
        // SPEC/game/extraction-and-improvements.md § Capital tile grain bonus
        // (Great Powers). Non-GP factions must not.
        const provinceId = 'oldWorld|m1';
        final game = gameForNonGpExtractionTest(
          provinces: [
            capitalProvinceForNonGpExtractionTest(provinceId: provinceId),
          ],
          capitalTileGrainBonusPerTurn: 5,
          minorNations: [testMinor()],
        );

        final result = computeNonGreatPowerExtraction(
          game: game,
          tileMapByRegion: {
            'oldWorld': tileMapAllInProvinceForNonGpExtractionTest(
              provinceId: provinceId,
              width: 1,
              height: 1,
              resources: const [
                [null],
              ],
            ),
          },
          connectivityByFactionId: {
            'm1': ConnectivityResult(connected: const <String>{}),
          },
        );

        // No connected tiles + no bonus → minor produces nothing this turn and
        // is not even present in the per-faction output map.
        expect(result, isNot(contains('m1')));
      },
    );

    test(
      'non-GP output is land-only (SPEC AC: no overseas bucket, no GP-side '
      'side-effects on Player.stockpile)',
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
          connectivityByFactionId: {
            'm1': ConnectivityResult(connected: {'oldWorld|m1|0|0'}),
          },
        );

        // The returned map's keys are faction ids and values are flat
        // commodity → quantity maps. There is no overseas bucket exposed by
        // the contract, and no `Player.stockpile` mutation is observable —
        // the game value is reused unchanged by callers (verified by the
        // contract; no `Game` is returned).
        expect(result['m1'], equals(<CommodityId, int>{'timber': 1}));
        expect(result['m1']?.keys, hasLength(1));
      },
    );
  });
}
