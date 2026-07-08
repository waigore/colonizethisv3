import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/suggestion/valid_work_tiles_test_support.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'getValidWorkOrderTileKeysWithVisibility explore only scans partially revealed provinces',
      () {
        const partialProvince = 'oldWorld|p_partial';
        const fullProvince = 'oldWorld|p_full';
        const unknownProvince = 'oldWorld|p_unknown';
        const partialKnownTile = 'oldWorld|p_partial|0|0';
        const partialUnknownTile = 'oldWorld|p_partial|1|0';
        const fullTile = 'oldWorld|p_full|0|0';
        const unknownTile = 'oldWorld|p_unknown|0|0';

        final explorer = ValidWorkTilesTestSupport.explorerUnit(
          locationProvinceId: partialProvince,
          tileKey: partialKnownTile,
        );
        final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
          tribes: const [ValidWorkTilesTestSupport.defaultTribe],
          // Refs #3753 R4: explore/prospect in a Tribe province require a
          // Consulate (or higher); the suggestion path shares the work-order
          // validator, so a consulate is needed for these tiles to be valid.
          overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
          oldWorld: RegionData(
            provinces: [
              Province(
                id: partialProvince,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: 'tribe1',
              ),
              Province(
                id: fullProvince,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: 'tribe1',
              ),
              Province(
                id: unknownProvince,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: 'tribe1',
              ),
            ],
            units: [explorer],
          ),
          tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
            {
              partialProvince: [partialKnownTile, partialUnknownTile],
              fullProvince: [fullTile],
              unknownProvince: [unknownTile],
            },
          ),
          playerVisibilityByTile: const {
            ValidWorkTilesTestSupport.playerId: {
              partialKnownTile: 'fogged',
              fullTile: 'fullyVisible',
              unknownTile: 'unknown',
            },
          },
        );
        final view = buildPlayerView(
          game,
          ValidWorkTilesTestSupport.emptyTopology,
          ValidWorkTilesTestSupport.playerId,
        );

        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: ValidWorkTilesTestSupport.emptyTopology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetExplore,
          currentOrders: const Orders(),
        );

        expect(valid, contains(partialKnownTile));
        expect(valid, isNot(contains(fullTile)));
        expect(valid, isNot(contains(unknownTile)));
      },
    );

    test(
      'getValidWorkOrderTileKeysWithVisibility explore remains under one second on large map fixture',
      () {
        const provinceCount = 120;
        const tilesPerProvince = 12;
        final byProvince = <String, List<String>>{};
        final visibility = <String, String>{};
        final provinces = <Province>[];

        for (var p = 0; p < provinceCount; p++) {
          final provinceId = ValidWorkTilesTestSupport.provinceId('p$p');
          provinces.add(
            Province(
              id: provinceId,
              regionId: ValidWorkTilesTestSupport.ow,
              ownerId: 'tribe1',
            ),
          );
          final tiles = <String>[];
          for (var t = 0; t < tilesPerProvince; t++) {
            final tileKey = ValidWorkTilesTestSupport.tileKey('p$p', t, 0);
            tiles.add(tileKey);
            if (p.isEven && t == 0) {
              visibility[tileKey] = 'fogged';
            } else if (p.isEven && t == 1) {
              visibility[tileKey] = 'unknown';
            } else {
              visibility[tileKey] = 'unknown';
            }
          }
          byProvince[provinceId] = tiles;
        }

        final startTile = ValidWorkTilesTestSupport.tileKey('p0', 0, 0);
        final explorer = ValidWorkTilesTestSupport.explorerUnit(
          locationProvinceId: ValidWorkTilesTestSupport.provinceId('p0'),
          tileKey: startTile,
        );
        final game = ValidWorkTilesTestSupport.validWorkTilesGame(
          id: 'g-latency',
          tribes: const [ValidWorkTilesTestSupport.defaultTribe],
          // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
          overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
          oldWorld: RegionData(provinces: provinces, units: [explorer]),
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(byProvince),
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: visibility,
          },
        );
        final view = buildPlayerView(
          game,
          ValidWorkTilesTestSupport.emptyTopology,
          ValidWorkTilesTestSupport.playerId,
        );

        final sw = Stopwatch()..start();
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: ValidWorkTilesTestSupport.emptyTopology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetExplore,
          currentOrders: const Orders(),
        );
        sw.stop();

        expect(valid, isNotEmpty);
        expect(sw.elapsedMilliseconds, lessThan(1000));
      },
    );
  });
}
