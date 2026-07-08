import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/suggestion/valid_work_tiles_test_support.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test('returns empty for unknown unit id', () {
      final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
        tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
          {
            ValidWorkTilesTestSupport.provinceId('p1'): [
              ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
            ],
          },
        ),
      );
      final valid = getValidWorkOrderTileKeys(
        game,
        ValidWorkTilesTestSupport.emptyTopology,
        ValidWorkTilesTestSupport.playerId,
        'no-such-unit',
        kWorkTargetExplore,
        const Orders(),
      );
      expect(valid, isEmpty);
    });

    test('returns empty when workTarget not allowed for unit type', () {
      final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
      final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
      final unit = ValidWorkTilesTestSupport.explorerUnit(
        locationProvinceId: provinceId,
        tileKey: tile,
      );
      final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
        oldWorld: RegionData(
          provinces: [
            Province(
              id: provinceId,
              regionId: ValidWorkTilesTestSupport.ow,
              ownerId: ValidWorkTilesTestSupport.playerId,
            ),
          ],
          units: [unit],
        ),
        tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
          {provinceId: [tile]},
        ),
      );
      final valid = getValidWorkOrderTileKeys(
        game,
        ValidWorkTilesTestSupport.emptyTopology,
        ValidWorkTilesTestSupport.playerId,
        'u1',
        kWorkTargetBuildImprovement,
        const Orders(),
      );
      expect(valid, isEmpty);
    });

    test('returns empty for unknown unit id with visibility', () {
      final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
        tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
          {
            ValidWorkTilesTestSupport.provinceId('p1'): [
              ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
            ],
          },
        ),
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
        unitId: 'no-such-unit',
        workTarget: kWorkTargetExplore,
        currentOrders: const Orders(),
      );
      expect(valid, isEmpty);
    });

    test(
      'returns empty when workTarget not allowed for unit type with visibility',
      () {
        final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
        final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final unit = ValidWorkTilesTestSupport.explorerUnit(
          locationProvinceId: provinceId,
          tileKey: tile,
        );
        final game = ValidWorkTilesTestSupport.validWorkTilesGame(
          oldWorld: RegionData(
            provinces: [
              Province(
                id: provinceId,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: ValidWorkTilesTestSupport.playerId,
              ),
            ],
            units: [unit],
          ),
          tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
            {provinceId: [tile]},
          ),
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
          workTarget: kWorkTargetBuildImprovement,
          currentOrders: const Orders(),
        );
        expect(valid, isEmpty);
      },
    );

    test('filters by visibility before order engine validation', () {
      final p1 = ValidWorkTilesTestSupport.provinceId('p1');
      final p2 = ValidWorkTilesTestSupport.provinceId('p2');
      final tileP1 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
      final tileP2 = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
      final unit = Unit(
        id: 'u1',
        type: 'Colonist',
        ownerId: ValidWorkTilesTestSupport.playerId,
        locationProvinceId: p1,
        tileKey: tileP1,
      );
      final game = ValidWorkTilesTestSupport.validWorkTilesGame(
        oldWorld: RegionData(
          provinces: [
            Province(
              id: p1,
              regionId: ValidWorkTilesTestSupport.ow,
              ownerId: ValidWorkTilesTestSupport.playerId,
            ),
          ],
          units: [unit],
        ),
        tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
          {
            p1: [tileP1],
            p2: [tileP2],
          },
        ),
      );

      final viewWithFullVisibility = buildPlayerView(
        game,
        ValidWorkTilesTestSupport.emptyTopology,
        ValidWorkTilesTestSupport.playerId,
      );

      final validWithVisibility = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: ValidWorkTilesTestSupport.emptyTopology,
        view: viewWithFullVisibility,
        unitId: 'u1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );

      final validWithoutVisibility = getValidWorkOrderTileKeys(
        game,
        ValidWorkTilesTestSupport.emptyTopology,
        ValidWorkTilesTestSupport.playerId,
        'u1',
        kWorkTargetBuildImprovement,
        const Orders(),
      );

      expect(validWithVisibility.length, validWithoutVisibility.length);
    });
  });
}
