import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('resolveTileKeyResourceContext', () {
    final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
      provinceId: 'oldWorld|p1',
      width: 2,
      height: 1,
      resources: [
        [Resource.grain, Resource.iron],
      ],
    );

    test('returns resource context for valid tile key', () {
      final ctx = resolveTileKeyResourceContext(
        tileKey: 'oldWorld|p1|0|0',
        tileMapByRegion: {'oldWorld': tileMap},
      );

      expect(ctx, isNotNull);
      expect(ctx!.commodityId, CommodityCatalog.grain.id);
      expect(ctx.provinceId, 'oldWorld|p1');
      expect(ctx.resource, Resource.grain);
    });

    test('maps commodity id via resource.name consistently', () {
      final ctx = resolveTileKeyResourceContext(
        tileKey: 'oldWorld|p1|1|0',
        tileMapByRegion: {'oldWorld': tileMap},
      );

      expect(ctx!.commodityId, Resource.iron.name);
      expect(ctx.commodityId, CommodityCatalog.iron.id);
    });

    test('returns null for invalid or out-of-range keys', () {
      expect(
        resolveTileKeyResourceContext(
          tileKey: 'bad-key',
          tileMapByRegion: {'oldWorld': tileMap},
        ),
        isNull,
      );
      expect(
        resolveTileKeyResourceContext(
          tileKey: 'oldWorld|p1|-1|0',
          tileMapByRegion: {'oldWorld': tileMap},
        ),
        isNull,
      );
      expect(
        resolveTileKeyResourceContext(
          tileKey: 'newWorld|p1|0|0',
          tileMapByRegion: {'oldWorld': tileMap},
        ),
        isNull,
      );
    });
  });

  group('resolveTileKeyExtractionContext', () {
    const provinceId = 'oldWorld|p1';
    final province = capitalProvinceForNonGpExtractionTest(
      provinceId: provinceId,
    );
    final tileMap = tileMapAllInProvinceForNonGpExtractionTest(
      provinceId: provinceId,
      width: 1,
      height: 1,
      resources: [
        [Resource.grain],
      ],
    );
    final tileMapByRegion = {'oldWorld': tileMap};

    test('resolves province from provincesByFullId index', () {
      final ctx = resolveTileKeyExtractionContext(
        tileKey: '$provinceId|0|0',
        tileMapByRegion: tileMapByRegion,
        provincesByFullId: {provinceId: province},
        logContext: 'test',
      );

      expect(ctx, isNotNull);
      expect(ctx!.province.id, provinceId);
      expect(ctx.commodityId, CommodityCatalog.grain.id);
    });

    test('falls back to game.worldState when index misses', () {
      final game = gameForNonGpExtractionTest(provinces: [province]);
      final ctx = resolveTileKeyExtractionContext(
        tileKey: '$provinceId|0|0',
        tileMapByRegion: tileMapByRegion,
        game: game,
        logContext: 'test',
      );

      expect(ctx!.province.id, provinceId);
    });

    test('returns null when province row is missing', () {
      final ctx = resolveTileKeyExtractionContext(
        tileKey: '$provinceId|0|0',
        tileMapByRegion: tileMapByRegion,
        provincesByFullId: const {},
        logContext: 'test',
      );

      expect(ctx, isNull);
    });
  });
}
