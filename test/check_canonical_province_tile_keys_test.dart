import 'package:test/test.dart';

import '../tool/check_canonical_province_tile_keys.dart';

void main() {
  group('findCanonicalProvinceTileKeyViolations', () {
    test('accepts non-anchor full tile key for province-level work target', () {
      const src = r'''
void f() {
  final o = WorkOrder(
    unitId: 'u1',
    target: 'explore',
    targetTileKey: 'oldWorld|p1|3|4',
  );
  print(o);
}
''';
      final violations = findCanonicalProvinceTileKeyViolations(
        relativePath: 'packages/foo/lib/example.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('accepts full tile key for province-level work target', () {
      const src = r'''
void f() {
  final o = WorkOrder(
    unitId: 'u1',
    target: 'counter_spy',
    targetTileKey: 'oldWorld|p1|0|0',
  );
  print(o);
}
''';
      final violations = findCanonicalProvinceTileKeyViolations(
        relativePath: 'packages/foo/lib/example.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('flags malformed province-level work-order tile key', () {
      const src = r'''
void f() {
  final o = WorkOrder(
    unitId: 'u1',
    target: 'explore',
    targetTileKey: 'oldWorld|p1',
  );
  print(o);
}
''';
      final violations = findCanonicalProvinceTileKeyViolations(
        relativePath: 'packages/foo/lib/example.dart',
        source: src,
      );
      expect(violations, isNotEmpty);
    });

    test('ignores non-province-level work targets', () {
      const src = r'''
void f() {
  final o = WorkOrder(
    unitId: 'u1',
    target: 'build_improvement',
    targetTileKey: 'oldWorld|p1|3|4',
  );
  print(o);
}
''';
      final violations = findCanonicalProvinceTileKeyViolations(
        relativePath: 'packages/foo/lib/example.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
