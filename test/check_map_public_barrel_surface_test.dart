import 'package:test/test.dart';

import '../tool/check_map_public_barrel_surface.dart';

void main() {
  group('findMapPublicBarrelViolations', () {
    test('flags a re-export of an internal-only grid_voronoi module', () {
      const src = r'''
library;

export 'src/grid_voronoi.dart';
export 'src/tile_map_generator.dart';
''';
      final violations = findMapPublicBarrelViolations(source: src);
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('grid_voronoi.dart'));
    });

    test('flags every forbidden internal module re-export', () {
      const src = r'''
export 'src/grid_voronoi.dart';
export 'src/topology_inference.dart';
export 'src/tile_map_grid_graph.dart';
''';
      final violations = findMapPublicBarrelViolations(source: src);
      expect(violations, hasLength(3));
    });

    test('accepts a barrel that exports only intentional entry points', () {
      const src = r'''
library;

export 'src/topology_generator.dart';
export 'src/tile_map_generator.dart';
export 'src/tile_map_generator_land_seeds.dart';
export 'src/map_partition_gates_exhausted.dart';
''';
      final violations = findMapPublicBarrelViolations(source: src);
      expect(violations, isEmpty);
    });

    test('does not flag a comment mentioning an internal module', () {
      const src = r'''
// Internal-only: src/grid_voronoi.dart is imported from src/ in tests only.
export 'src/tile_map_generator.dart';
''';
      final violations = findMapPublicBarrelViolations(source: src);
      expect(violations, isEmpty);
    });

    test('does not flag a same-package src import (not an export)', () {
      const src = r'''
import 'src/grid_voronoi.dart';
export 'src/tile_map_generator.dart';
''';
      final violations = findMapPublicBarrelViolations(source: src);
      expect(violations, isEmpty);
    });
  });
}
