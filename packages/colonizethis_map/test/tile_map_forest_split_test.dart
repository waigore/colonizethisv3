import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

import 'support/tile_map_gen_fixtures.dart';

/// Map-generation integration tests for the forest split (issue #3573):
/// guaranteed forest resource spawn (R3 / AC3) and hardwood clustering
/// (R7 / AC7). SPEC/program/tile-map-gen-resources.md,
/// SPEC/program/tile-map-gen-algorithm.md.
void main() {
  suppressLogsForTests();

  TileMapResult generate(String regionId, {int seed = 42}) {
    final params = genParams(
      width: 80,
      height: 80,
      seed: seed,
      seaFraction: 0.4,
    );
    final (result, _) = TileMapGenerator(params: params).generate(
      numProvinces: 40,
      numContinents: 2,
      regionId: regionId,
      resourceRules: ResourceRules.defaultRules,
    );
    return result;
  }

  List<(int x, int y)> cellsOfTerrain(TileMapResult r, TerrainType t) {
    final out = <(int x, int y)>[];
    for (var y = 0; y < r.height; y++) {
      for (var x = 0; x < r.width; x++) {
        if (r.terrainAt(x, y) == t) out.add((x, y));
      }
    }
    return out;
  }

  group('guaranteed forest resource spawn (AC3 #3573)', () {
    test('every scrub forest cell has timber (Old World)', () {
      final r = generate('oldWorld');
      final scrub = cellsOfTerrain(r, TerrainType.scrubForest);
      expect(scrub, isNotEmpty);
      for (final (x, y) in scrub) {
        expect(r.resourceAt(x, y), Resource.timber);
      }
    });

    test('every hardwood forest cell has timber (Old World)', () {
      final r = generate('oldWorld');
      final hardwood = cellsOfTerrain(r, TerrainType.hardwoodForest);
      expect(hardwood, isNotEmpty);
      for (final (x, y) in hardwood) {
        expect(r.resourceAt(x, y), Resource.timber);
      }
    });

    test('every scrub forest cell has timber (New World)', () {
      final r = generate('newWorld');
      final scrub = cellsOfTerrain(r, TerrainType.scrubForest);
      expect(scrub, isNotEmpty);
      for (final (x, y) in scrub) {
        expect(r.resourceAt(x, y), Resource.timber);
      }
    });

    test(
      'every New World hardwood cell has furs or timber, trending 70/30',
      () {
        // Aggregate across several seeds to get a stable sample of NW hardwood.
        var furs = 0;
        var timber = 0;
        for (var seed = 1; seed <= 8; seed++) {
          final r = generate('newWorld', seed: seed);
          for (final (x, y) in cellsOfTerrain(r, TerrainType.hardwoodForest)) {
            final res = r.resourceAt(x, y);
            expect(res == Resource.furs || res == Resource.timber, isTrue);
            if (res == Resource.furs) furs++;
            if (res == Resource.timber) timber++;
          }
        }
        expect(furs + timber, greaterThan(50));
        final fursFraction = furs / (furs + timber);
        // Wide tolerance: clustering/cell-count noise plus finite sample.
        expect(fursFraction, closeTo(0.7, 0.2));
      },
    );
  });

  group('hardwood clustering (AC7 #3573)', () {
    bool hasForestNeighbor(TileMapResult r, int x, int y) {
      const dirs = [(0, -1), (1, 0), (0, 1), (-1, 0)];
      for (final (dx, dy) in dirs) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= r.width || ny < 0 || ny >= r.height) continue;
        final t = r.terrainAt(nx, ny);
        if (t == TerrainType.hardwoodForest || t == TerrainType.scrubForest) {
          return true;
        }
      }
      return false;
    }

    test('most hardwood cells are adjacent to hardwood or scrub forest', () {
      final r = generate('oldWorld');
      final hardwood = cellsOfTerrain(r, TerrainType.hardwoodForest);
      expect(hardwood.length, greaterThan(3));
      final clustered = hardwood
          .where((c) => hasForestNeighbor(r, c.$1, c.$2))
          .length;
      // Clustering should attach the large majority of hardwood cells to a
      // forest neighbour; graceful degradation allows a few isolated ones.
      expect(clustered / hardwood.length, greaterThan(0.6));
    });

    test('hardwood remains rarer than scrub (1:4 weight ratio preserved)', () {
      final r = generate('oldWorld');
      final hardwood = cellsOfTerrain(r, TerrainType.hardwoodForest).length;
      final scrub = cellsOfTerrain(r, TerrainType.scrubForest).length;
      expect(hardwood, greaterThan(0));
      expect(scrub, greaterThan(hardwood));
    });
  });
}
