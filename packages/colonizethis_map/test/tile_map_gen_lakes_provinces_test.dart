import 'dart:math';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_map/src/gen/map_gen_pass_payloads.dart';
import 'package:colonizethis_map/src/gen/map_gen_stage.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_continent_join_pass.dart';
import 'package:colonizethis_map/src/gen/tile_map_generator_lakes_provinces.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph.dart';
import 'package:colonizethis_test/test.dart';

// Direct unit tests for the standalone `TileMapGenLakesProvinces` class
// (extracted from a `part of 'tile_map_generator.dart'` fragment, Refs #3588).
// These construct the pass directly — no `TileMapGenerator` orchestration — to
// confirm the class is individually testable.
void main() {
  const sea = 's1';
  const land = '_land';

  TileMapGenLakesProvinces buildPass(TileMapParams params) {
    final graph = TileMapGridGraph(params);
    final join = ContinentJoinPass(params, packageLogger(), graph);
    return TileMapGenLakesProvinces(params, graph, join);
  }

  group('TileMapGenLakesProvinces (standalone, direct construction)', () {
    test('run with skipFillLakes leaves the grid unchanged and logs skips', () {
      final params = TileMapParams(
        width: 4,
        height: 3,
        skipFillLakes: true,
      );
      final pass = buildPass(params);
      final grid = <List<String>>[
        [land, sea, sea, land],
        [land, sea, sea, land],
        [land, land, land, land],
      ];
      final lines = <String>[];

      final out = pass.run(
        MapGenPassContext<LakesPassPayload>(
          params: params,
          payload: LakesPassPayload(
            grid: grid.map((r) => r.toList()).toList(),
            seaZoneId: sea,
            landSeeds: const [(0, 1)],
            continentBySeedIndex: const [0],
            rnd: Random(1),
          ),
          onLog: lines.add,
        ),
      );

      expect(out, equals(grid));
      expect(
        lines,
        containsAll(<String>[
          'Pass 4: Fill lakes and moats skipped',
          'Pass 5: Border noise skipped (0)',
        ]),
      );
    });

    test('fillLakes converts an enclosed single-continent lake to land', () {
      final params = TileMapParams(width: 5, height: 3);
      final pass = buildPass(params);
      final grid = <List<String>>[
        [land, sea, sea, sea, land],
        [land, sea, sea, sea, land],
        [land, land, land, land, land],
      ];

      final out = pass.fillLakes(grid, sea, const [(2, 2)], const [0]);

      expect(out[0].every((c) => c == land), isTrue);
      expect(out[1].every((c) => c == land), isTrue);
    });

    test('fillLakes preserves a two-continent strait as sea', () {
      final params = TileMapParams(width: 4, height: 3);
      final pass = buildPass(params);
      final grid = <List<String>>[
        [land, sea, sea, land],
        [land, sea, sea, land],
        [land, land, land, land],
      ];

      final out = pass.fillLakes(
        grid,
        sea,
        const [(0, 0), (3, 0)],
        const [0, 1],
      );

      final seaCount = out
          .expand((row) => row)
          .where((c) => c == sea)
          .length;
      expect(seaCount, greaterThan(0));
    });

    test('assignProvincesFromSeeds replaces land sentinels with seed ids', () {
      final params = TileMapParams(width: 3, height: 3);
      final pass = buildPass(params);
      final grid = <List<String>>[
        [land, land, sea],
        [land, land, sea],
        [sea, sea, sea],
      ];

      final out = pass.assignProvincesFromSeeds(grid, const {
        'p1': (0, 0),
      }, sea);

      // Every former land sentinel is now the single province id; sea untouched.
      expect(out[0][0], 'p1');
      expect(out[1][1], 'p1');
      expect(out[2][2], sea);
      expect(out.expand((r) => r).contains(land), isFalse);
    });

    test('assignProvincesFromSeeds returns grid unchanged with no seeds', () {
      final params = TileMapParams(width: 2, height: 2);
      final pass = buildPass(params);
      final grid = <List<String>>[
        [land, land],
        [sea, sea],
      ];

      final out = pass.assignProvincesFromSeeds(
        grid,
        const <String, (int x, int y)>{},
        sea,
      );

      expect(identical(out, grid), isTrue);
    });
  });
}
