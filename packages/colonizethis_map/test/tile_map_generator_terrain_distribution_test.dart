import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'support/tile_map_gen_fixtures.dart';

void main() {
  group('TileMapGenerator terrain distribution', () {
    test(
      'mountain fraction is close to configured distribution and forms ridges',
      () {
        const w = 40;
        const h = 30;
        final params = genParams(
          width: w,
          height: h,
          seed: 10,
        );
        final (result, _) = TileMapGenerator(params: params).generate(
          numProvinces: 4,
          numContinents: 1,
          regionId: 'oldWorld',
          resourceRules: ResourceRules.defaultRules,
        );
        final dist = terrainDistributionForRegion('oldWorld');
        var landCount = 0;
        var mountainCount = 0;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            final id = result.cell(x, y);
            if (!RegExp(r'^s\d+$').hasMatch(id)) {
              landCount++;
              if (result.terrainAt(x, y) == TerrainType.mountain) {
                mountainCount++;
              }
            }
          }
        }
        if (landCount == 0) return;
        final target = dist.mountainFraction * landCount;
        // Allow generous tolerance; we only require approximate adherence.
        expect(mountainCount, greaterThan(0));
        expect(
          mountainCount,
          inInclusiveRange((target * 0.4).round(), (target * 1.6).round()),
          reason:
              'mountain count $mountainCount should be within a factor of target $target',
        );

        // Check that there exists at least one elongated mountain component
        // (roughly ridge-like rather than a tiny blob).
        final seen = <(int, int)>{};
        final directions = <(int, int)>[(0, -1), (1, 0), (0, 1), (-1, 0)];
        var hasElongated = false;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (result.terrainAt(x, y) != TerrainType.mountain) continue;
            if (seen.contains((x, y))) continue;
            final queue = <(int, int)>[(x, y)];
            final component = <(int, int)>{(x, y)};
            seen.add((x, y));
            while (queue.isNotEmpty) {
              final (cx, cy) = queue.removeLast();
              for (final (dx, dy) in directions) {
                final nx = cx + dx;
                final ny = cy + dy;
                if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
                if (result.terrainAt(nx, ny) != TerrainType.mountain) continue;
                if (component.add((nx, ny))) {
                  seen.add((nx, ny));
                  queue.add((nx, ny));
                }
              }
            }
            final size = component.length;
            if (size < 5) continue;
            var minX = w;
            var maxX = 0;
            var minY = h;
            var maxY = 0;
            for (final (cx, cy) in component) {
              if (cx < minX) minX = cx;
              if (cx > maxX) maxX = cx;
              if (cy < minY) minY = cy;
              if (cy > maxY) maxY = cy;
            }
            final spanX = (maxX - minX + 1);
            final spanY = (maxY - minY + 1);
            final maxSpan = spanX > spanY ? spanX : spanY;
            if (maxSpan >= 2 && size / maxSpan >= 2) {
              hasElongated = true;
              break;
            }
          }
          if (hasElongated) break;
        }
        expect(
          hasElongated,
          isTrue,
          reason: 'expected at least one elongated mountain component',
        );
      },
    );

    test('non-mountain terrain quotas roughly follow distribution', () {
      const w = 40;
      const h = 30;
      final params = genParams(
        width: w,
        height: h,
        seed: 20,
      );
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 4,
        numContinents: 1,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      final dist = terrainDistributionForRegion('oldWorld');
      final counts = <TerrainType, int>{
        for (final t in TerrainType.values) t: 0,
      };
      var landCount = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final id = result.cell(x, y);
          if (RegExp(r'^s\d+$').hasMatch(id)) continue;
          landCount++;
          final t = result.terrainAt(x, y);
          if (t != null) {
            counts[t] = (counts[t] ?? 0) + 1;
          }
        }
      }
      if (landCount == 0) return;

      for (final t in TerrainType.values) {
        final frac = dist.fractionFor(t);
        if (frac == 0) continue;
        final expected = frac * landCount;
        final actual = counts[t] ?? 0;
        // Allow a generous band; we only require approximate adherence over the
        // map and small-fraction terrains (like swamp) can deviate more.
        if (expected < 50) {
          // For rare terrains, just assert they do not dominate the map.
          expect(
            actual,
            lessThanOrEqualTo((landCount * 0.5).round()),
            reason:
                'terrain $t has $actual tiles, expected roughly $expected (land=$landCount)',
          );
        } else {
          final lower = (expected * 0.3).round();
          final upper = (expected * 2.2).round();
          expect(
            actual,
            inInclusiveRange(lower, upper),
            reason:
                'terrain $t has $actual tiles, expected roughly $expected (land=$landCount)',
          );
        }
      }
    });
  });
}
