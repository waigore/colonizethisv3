import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_map_public_barrel_surface.dart';

void main() {
  group('findForbiddenExportViolations', () {
    test('flags a re-export of an internal-only grid_voronoi module', () {
      const src = r'''
library;

export 'src/gen/grid_voronoi.dart';
export 'src/gen/tile_map_generator.dart';
''';
      final violations = findForbiddenExportViolations(
        relativeFilePath: 'packages/colonizethis_map/lib/colonizethis_map.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('grid_voronoi.dart'));
    });

    test('flags every forbidden internal module re-export', () {
      const src = r'''
export 'src/gen/grid_voronoi.dart';
export 'src/gen/topology_inference.dart';
export 'src/gen/tile_map_grid_graph.dart';
export 'src/gen/tile_map_generator_lakes_test_api.dart';
''';
      final violations = findForbiddenExportViolations(
        relativeFilePath: 'packages/colonizethis_map/lib/colonizethis_map.dart',
        source: src,
      );
      expect(violations, hasLength(4));
    });

    test('flags *_test_api.dart re-exports', () {
      const src = r'''
export 'src/gen/tile_map_generator_lakes_test_api.dart';
''';
      final violations = findForbiddenExportViolations(
        relativeFilePath:
            'packages/colonizethis_map/lib/src/gen/tile_map_generator.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('accepts a barrel that exports only intentional entry points', () {
      const src = r'''
library;

export 'src/topology_generator.dart';
export 'src/tile_map_generator.dart';
export 'src/tile_map_generator_land_seeds.dart';
export 'src/map_partition_gates_exhausted.dart';
''';
      final violations = findForbiddenExportViolations(
        relativeFilePath: 'packages/colonizethis_map/lib/colonizethis_map.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment mentioning an internal module', () {
      const src = r'''
// Internal-only: src/grid_voronoi.dart is imported from src/ in tests only.
export 'src/tile_map_generator.dart';
''';
      final violations = findForbiddenExportViolations(
        relativeFilePath: 'packages/colonizethis_map/lib/colonizethis_map.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a same-package src import (not an export)', () {
      const src = r'''
import 'src/grid_voronoi.dart';
export 'src/tile_map_generator.dart';
''';
      final violations = findForbiddenExportViolations(
        relativeFilePath: 'packages/colonizethis_map/lib/colonizethis_map.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });

  group('collectTransitiveExportClosure', () {
    test('follows nested export targets from the public barrel', () {
      final temp = Directory.systemTemp.createTempSync('map_barrel_closure_');
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/packages/colonizethis_map/lib/colonizethis_map.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("export 'src/gen/tile_map_generator.dart';\n");
      File(
        '${temp.path}/packages/colonizethis_map/lib/src/gen/tile_map_generator.dart',
      )
        ..createSync(recursive: true)
        ..writeAsStringSync("export 'tile_map_params.dart';\n");
      File(
        '${temp.path}/packages/colonizethis_map/lib/src/gen/tile_map_params.dart',
      )
        ..createSync(recursive: true)
        ..writeAsStringSync('class TileMapParams {}\n');

      final closure = collectTransitiveExportClosure(
        repoRoot: temp.path,
        barrelRelativePath: 'packages/colonizethis_map/lib/colonizethis_map.dart',
      );
      expect(
        closure,
        containsAll([
          'packages/colonizethis_map/lib/colonizethis_map.dart',
          'packages/colonizethis_map/lib/src/gen/tile_map_generator.dart',
          'packages/colonizethis_map/lib/src/gen/tile_map_params.dart',
        ]),
      );
    });
  });
}
