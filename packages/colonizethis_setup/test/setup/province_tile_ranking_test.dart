// SPEC/game/tile-map-and-generation.md § Great Power starting grain;
// SPEC/game/factions.md § Starting developed resources.
// Direct unit tests for the shared province tile ranker (province_tile_ranking.dart)
// that now backs grain and minor/tribe development selection (Refs #3712).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/src/setup/province_tile_ranking.dart';
import 'package:colonizethis_test/test.dart';

TileMapResult _province4x3() => TileMapResult(
  width: 4,
  height: 3,
  grid: const [
    ['p1', 'p1', 'p1', 'p1'],
    ['p1', 'p1', 'p1', 'p1'],
    ['p1', 'p1', 'p1', 'p1'],
  ],
);

CapitalTile _capitalAt(int x, int y) =>
    CapitalTile(regionId: 'oldWorld', provinceId: 'oldWorld|p1', x: x, y: y);

void main() {
  group('rankProvinceTileKeysByDistance', () {
    test('orders by Manhattan distance, then y asc, then x asc', () {
      final picks = rankProvinceTileKeysByDistance(
        map: _province4x3(),
        capital: _capitalAt(2, 1),
        accept: (_, __, ___) => true,
        maxTiles: 5,
      );
      // (2,1) d=0 first, then the four distance-1 tiles sorted y asc, x asc.
      expect(picks, [
        'oldWorld|p1|2|1',
        'oldWorld|p1|2|0',
        'oldWorld|p1|1|1',
        'oldWorld|p1|3|1',
        'oldWorld|p1|2|2',
      ]);
    });

    test('caps output at maxTiles', () {
      final picks = rankProvinceTileKeysByDistance(
        map: _province4x3(),
        capital: _capitalAt(0, 0),
        accept: (_, __, ___) => true,
        maxTiles: 2,
      );
      expect(picks, ['oldWorld|p1|0|0', 'oldWorld|p1|1|0']);
    });

    test('returns all eligible tiles in order when maxTiles is null', () {
      final picks = rankProvinceTileKeysByDistance(
        map: _province4x3(),
        capital: _capitalAt(0, 0),
        accept: (_, __, ___) => true,
      );
      expect(picks, hasLength(12));
      expect(picks.first, 'oldWorld|p1|0|0');
    });

    test('applies the eligibility predicate and excludes other provinces', () {
      final map = TileMapResult(
        width: 2,
        height: 2,
        grid: const [
          ['p1', 'p2'],
          ['p2', 'p1'],
        ],
      );
      final picks = rankProvinceTileKeysByDistance(
        map: map,
        capital: _capitalAt(0, 0),
        // Reject the capital tile itself; only the other p1 tile (1,1) remains.
        accept: (x, y, key) => key != 'oldWorld|p1|0|0',
      );
      expect(picks, ['oldWorld|p1|1|1']);
    });

    test('builds keys via the canonical CapitalTile.tileKey shape', () {
      final picks = rankProvinceTileKeysByDistance(
        map: _province4x3(),
        capital: _capitalAt(0, 0),
        accept: (_, __, ___) => true,
        maxTiles: 1,
      );
      expect(
        picks.single,
        CapitalTile.tileKey('oldWorld', 'oldWorld|p1', 0, 0),
      );
    });
  });
}
