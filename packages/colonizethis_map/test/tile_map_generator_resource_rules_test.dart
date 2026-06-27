import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'support/tile_map_gen_fixtures.dart';

void main() {
  group('TileMapGenerator resource rules', () {
    test(
      'with resourceRules produces terrain and resource grids of same dimensions',
      () {
        final params = genParams(
          width: 20,
          height: 15,
          seed: 2,
        );
        final (result, _) = TileMapGenerator(params: params).generate(
          numProvinces: 1,
          numContinents: 1,
          regionId: 'oldWorld',
          resourceRules: ResourceRules.defaultRules,
        );
        expect(result.terrainGrid, isNotNull);
        expect(result.resourceGrid, isNotNull);
        expect(result.terrainGrid!.length, result.height);
        expect(result.resourceGrid!.length, result.height);
        for (var i = 0; i < result.height; i++) {
          expect(result.terrainGrid![i].length, result.width);
          expect(result.resourceGrid![i].length, result.width);
        }
      },
    );

    test('terrain and resource respect region and terrain rules', () {
      final params = genParams(
        width: 25,
        height: 25,
        seed: 3,
      );
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      final rules = ResourceRules.defaultRules;
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final t = result.terrainAt(x, y);
          final r = result.resourceAt(x, y);
          if (t != null && r != null) {
            expect(rules.isAllowedOnTerrain(r, t), isTrue);
            expect(rules.isAllowedInRegion(r, 'oldWorld'), isTrue);
          }
        }
      }
    });

    test('newWorld resources respect region and terrain rules', () {
      final params = genParams(
        width: 30,
        height: 30,
        seed: 17,
      );
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 2,
        numContinents: 1,
        regionId: 'newWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      final rules = ResourceRules.defaultRules;
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final t = result.terrainAt(x, y);
          final r = result.resourceAt(x, y);
          if (t != null && r != null) {
            expect(rules.isAllowedOnTerrain(r, t), isTrue);
            expect(rules.isAllowedInRegion(r, 'newWorld'), isTrue);
          }
        }
      }
    });

    test(
      'multi-region resource cap: newWorld keeps both resources at or below cap',
      () {
        final params = genParams(
          width: 24,
          height: 24,
          seed: 42,
          seaFraction: 0.5,
        );
        final (result, _) = TileMapGenerator(params: params).generate(
          numProvinces: 2,
          numContinents: 1,
          regionId: 'newWorld',
          resourceRules: ResourceRules.defaultRules,
        );
        final rules = ResourceRules.defaultRules;
        var bothCount = 0;
        var totalCount = 0;
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            final r = result.resourceAt(x, y);
            if (r == null) continue;
            // Guaranteed forest resource placements (timber/furs) are excluded
            // from multi-region cap accounting (R3.5, issue #3573), mirroring
            // the bootstrap-grain exclusion; the cap governs only non-forest
            // cells. SPEC/program/tile-map-gen-resources.md.
            final terrain = result.terrainAt(x, y);
            if (terrain != null && isForestTerrain(terrain)) continue;
            totalCount++;
            if (rules.regionRule[r] == ResourceRegionRule.both) bothCount++;
          }
        }
        if (totalCount > 0) {
          final fraction = bothCount / totalCount;
          expect(
            fraction,
            lessThanOrEqualTo(0.35),
            reason:
                'bothCount=$bothCount totalCount=$totalCount fraction=$fraction',
          );
        }
      },
    );

    test(
      'multi-region resource cap: oldWorld respects region and terrain rules',
      () {
        final params = genParams(
          width: 24,
          height: 24,
          seed: 99,
          seaFraction: 0.5,
        );
        final (result, _) = TileMapGenerator(params: params).generate(
          numProvinces: 2,
          numContinents: 1,
          regionId: 'oldWorld',
          resourceRules: ResourceRules.defaultRules,
        );
        final rules = ResourceRules.defaultRules;
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            final t = result.terrainAt(x, y);
            final r = result.resourceAt(x, y);
            if (t != null && r != null) {
              expect(rules.isAllowedOnTerrain(r, t), isTrue);
              expect(rules.isAllowedInRegion(r, 'oldWorld'), isTrue);
            }
          }
        }
      },
    );

    test('ResourceRules.defaultRules covers all Resource enum values', () {
      final rules = ResourceRules.defaultRules;
      for (final r in Resource.values) {
        expect(
          rules.regionRule.containsKey(r),
          isTrue,
          reason: 'regionRule missing $r',
        );
        expect(
          rules.allowedTerrains.containsKey(r),
          isTrue,
          reason: 'allowedTerrains missing $r',
        );
        expect(
          rules.defaultMarketPrice.containsKey(r),
          isTrue,
          reason: 'defaultMarketPrice missing $r',
        );
      }
    });

    test('without resourceRules leaves terrain and resource grids null', () {
      final (result, _) = TileMapGenerator(
        params: genParams(width: 10, height: 10, seed: 1),
      ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
      expect(result.terrainGrid, isNull);
      expect(result.resourceGrid, isNull);
    });

    test('terrain on land uses only map region allowed set (oldWorld)', () {
      final (
        result,
        _,
      ) = TileMapGenerator(
        params: genParams(width: 25, height: 25, seed: 4),
      ).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      final allowed = allowedTerrainsForRegion('oldWorld').toSet();
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final t = result.terrainAt(x, y);
          if (t != null)
            expect(allowed.contains(t), isTrue, reason: 'terrain $t');
        }
      }
    });

    test('jitter params produce terrain and resource grids', () {
      final (result, _) =
          TileMapGenerator(
            params: genParams(
              width: 24,
              height: 24,
              seed: 3,
              jitterHomogeneityThreshold: 0.5,
              jitterProbability: 0.5,
              jitterMaxFraction: 0.2,
            ),
          ).generate(
            numProvinces: 2,
            numContinents: 1,
            regionId: 'oldWorld',
            resourceRules: ResourceRules.defaultRules,
          );
      expect(result.terrainGrid, isNotNull);
      expect(result.resourceGrid, isNotNull);
      expect(result.terrainGrid!.length, result.height);
      expect(result.resourceGrid!.length, result.height);
    });
  });
}
