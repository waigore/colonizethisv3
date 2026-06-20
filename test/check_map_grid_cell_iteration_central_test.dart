import 'package:test/test.dart';

import '../tool/check_map_grid_cell_iteration_central.dart';

void main() {
  group('findMapGridCellIterationViolations', () {
    test('flags a hand-rolled nested y/x tile-grid walk', () {
      const src = r'''
for (var y = 0; y < result.height; y++) {
  for (var x = 0; x < result.width; x++) {
    sink.add(result.cell(x, y));
  }
}
''';
      final violations = findMapGridCellIterationViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('TileMapGrid.forEachIndex'));
    });

    test('flags final/int loop variable declarations too', () {
      const src = r'''
for (final y = 0; y < h; y++) {
  for (int x = 0; x < w; x++) {
    use(x, y);
  }
}
''';
      final violations = findMapGridCellIterationViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('accepts the canonical TileMapGrid.forEachIndex delegation', () {
      const src = r'''
TileMapGrid.forEachIndex(result.height, result.width, (y, x) {
  sink.add(result.cell(x, y));
});
''';
      final violations = findMapGridCellIterationViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('accepts a nested walk with an inline allow marker on the header', () {
      const src = r'''
for (var y = 0; y < h; y++) { // ct-lint-allow: nested-grid-walk
  for (var x = 0; x < w; x++) {
    yield cell(x, y);
  }
}
''';
      final violations = findMapGridCellIterationViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('accepts a nested walk with an allow marker on the line above', () {
      const src = r'''
// ct-lint-allow: nested-grid-walk — sync* generator
for (var y = 0; y < h; y++) {
  for (var x = 0; x < w; x++) {
    yield cell(x, y);
  }
}
''';
      final violations = findMapGridCellIterationViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a y-loop without an adjacent inner x-loop', () {
      const src = r'''
for (var y = 0; y < rows.length; y++) {
  total += rows[y];
}
''';
      final violations = findMapGridCellIterationViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment describing a nested walk', () {
      const src = r'''
/// Replaces nested `for (var y …) { for (var x …) }` walks with forEachIndex.
final grid = TileMapGrid.filled(h, w, '');
''';
      final violations = findMapGridCellIterationViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
