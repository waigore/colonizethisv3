import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/src/tile_map_directions.dart';

import 'support/tile_map_gen_fixtures.dart';

void main() {
  group('Pass 4 lake fill (issue 1864)', () {
    test(
      'fillLakesPass4ForTest converts map-border single-continent bay to land',
      () {
        const sea = 's1';
        const land = '_land';
        final params = genParams(width: 5, height: 3);
        final grid = <List<String>>[
          [land, sea, sea, sea, land],
          [land, sea, sea, sea, land],
          [land, land, land, land, land],
        ];
        final out = TileMapGenerator.fillLakesPass4ForTest(
          params: params,
          grid: grid.map((r) => r.toList()).toList(),
          seaZoneId: sea,
          landSeeds: [(2, 2)],
          continentBySeedIndex: [0],
        );
        expect(out[0].every((c) => c == land), isTrue);
        expect(out[1].every((c) => c == land), isTrue);
      },
    );

    test('fillLakesPass4ForTest preserves two-continent border strait sea', () {
      const sea = 's1';
      const land = '_land';
      final params = genParams(width: 4, height: 3);
      final grid = <List<String>>[
        [land, sea, sea, land],
        [land, sea, sea, land],
        [land, land, land, land],
      ];
      final out = TileMapGenerator.fillLakesPass4ForTest(
        params: params,
        grid: grid.map((r) => r.toList()).toList(),
        seaZoneId: sea,
        landSeeds: [(0, 2), (3, 2)],
        continentBySeedIndex: [0, 1],
      );
      expect(out[0][1], sea);
      expect(out[0][2], sea);
      expect(out[1][1], sea);
      expect(out[1][2], sea);
    });

    test(
      'full generate seed-before-assignment still has edge-reachable sea',
      () {
        final (result, _) = TileMapGenerator(
          params: genParams(
            width: 28,
            height: 22,
            seed: 901,
            seaFraction: 0.58,
            seedBeforeAssignment: true,
          ),
        ).generate(numProvinces: 4, numContinents: 2, regionId: 'r1');
        final seaCells = <(int, int)>{};
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            if (RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) {
              seaCells.add((x, y));
            }
          }
        }
        if (seaCells.isEmpty) return;
        final queue = List<(int, int)>.from(
          seaCells.where(
            (p) =>
                p.$1 == 0 ||
                p.$1 == result.width - 1 ||
                p.$2 == 0 ||
                p.$2 == result.height - 1,
          ),
        );
        final reachable = queue.toSet();
        while (queue.isNotEmpty) {
          final (x, y) = queue.removeLast();
          for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < result.width && ny >= 0 && ny < result.height) {
              final nid = result.cell(nx, ny);
              if (RegExp(r'^s\d+$').hasMatch(nid) &&
                  !reachable.contains((nx, ny))) {
                reachable.add((nx, ny));
                queue.add((nx, ny));
              }
            }
          }
        }
        expect(reachable.length, seaCells.length);
      },
    );
  });
}
