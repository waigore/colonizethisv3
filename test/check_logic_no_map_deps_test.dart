import 'package:test/test.dart';

import '../tool/check_logic_no_map_deps.dart';

void main() {
  group('findLogicNoMapDepsViolations', () {
    test('flags an import of the colonizethis_map barrel', () {
      const src = r'''
import 'package:colonizethis_map/colonizethis_map.dart';
''';
      final violations = findLogicNoMapDepsViolations(
        relativePath: 'packages/colonizethis_logic/lib/src/foo.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.line, 1);
      expect(violations.single.message, contains('colonizethis_map'));
    });

    test('flags an export of a colonizethis_map src path', () {
      const src = r'''
export 'package:colonizethis_map/src/tile_map_grid.dart';
''';
      final violations = findLogicNoMapDepsViolations(
        relativePath: 'packages/colonizethis_logic/lib/colonizethis_logic.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('colonizethis_map'));
    });

    test('accepts imports of other colonizethis packages', () {
      const src = r'''
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
''';
      final violations = findLogicNoMapDepsViolations(
        relativePath: 'packages/colonizethis_logic/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment mentioning colonizethis_map', () {
      const src = r'''
/// The map barrel package:colonizethis_map is a dev dependency only.
import 'package:colonizethis_world/colonizethis_world.dart';
''';
      final violations = findLogicNoMapDepsViolations(
        relativePath: 'packages/colonizethis_logic/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a same-named-prefix package (colonizethis_map_x)', () {
      const src = r'''
import 'package:colonizethis_mapper/colonizethis_mapper.dart';
''';
      final violations = findLogicNoMapDepsViolations(
        relativePath: 'packages/colonizethis_logic/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
