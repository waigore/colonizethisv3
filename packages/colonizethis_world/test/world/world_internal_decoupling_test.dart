import 'dart:io';

import 'package:colonizethis_test/test.dart';

/// Source-level regression guard for the `province_lookup` <-> `province_owner_cache`
/// import cycle broken in Refs #3544 C1.
///
/// `oldWorldProvinceCountOwnedBy` was relocated from `province_lookup.dart` into
/// `province_owner_cache.dart` (its sole dependency), leaving a single one-way
/// edge `province_owner_cache -> province_lookup`. These tests assert the cycle
/// does not return and that no `src/world/` file re-introduces a
/// `package:colonizethis_world/src/world/` self-import (the obscuring pattern
/// that hid the original cycle; the rest of the package uses relative imports
/// for sibling `src/world/` files).
void main() {
  const worldDir = 'lib/src/world';

  String read(String relativePath) =>
      File('$worldDir/$relativePath').readAsStringSync();

  group('province lookup / owner cache cycle (Refs #3544 C1)', () {
    test('province_lookup.dart does not import province_owner_cache.dart', () {
      final source = read('province_lookup.dart');
      expect(
        source.contains('province_owner_cache'),
        isFalse,
        reason:
            'province_lookup.dart must not depend on province_owner_cache.dart; '
            'the cycle is broken by hosting oldWorldProvinceCountOwnedBy in '
            'province_owner_cache.dart.',
      );
    });

    test('province_owner_cache.dart keeps the one-way edge to province_lookup', () {
      final source = read('province_owner_cache.dart');
      expect(
        source.contains("import 'province_lookup.dart'"),
        isTrue,
        reason:
            'province_owner_cache may depend on province_lookup (one-way edge), '
            'and should do so via a relative import.',
      );
    });
  });

  test('no src/world file uses a package: self-import for a sibling src/world '
      'file', () {
    final dir = Directory(worldDir);
    final offenders = <String>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('import ') && !line.startsWith('export ')) continue;
        if (line.contains('package:colonizethis_world/src/world/')) {
          offenders.add('${entity.path}:${i + 1} -> $line');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'src/world/ files must reference sibling src/world/ libraries via '
          'relative imports, not package:colonizethis_world/src/world/ URIs '
          '(keeps intra-directory dependency edges visible). Offenders:\n'
          '${offenders.join('\n')}',
    );
  });
}
