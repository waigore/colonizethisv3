import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_no_duplicate_extension_helper.dart';

const _worldFileRel =
    'packages/colonizethis_world/lib/src/world/sample.dart';

void main() {
  group('findWorldDuplicateExtensionHelperViolations', () {
    test('accepts an expression-body delegator to the extension method', () {
      final violations = findWorldDuplicateExtensionHelperViolations(
        relativePath: _worldFileRel,
        source:
            'Iterable<Object> allProvinces(WorldState world) => '
            'world.allProvinces();',
      );
      expect(violations, isEmpty);
    });

    test('accepts a block-body single-return delegator', () {
      final violations = findWorldDuplicateExtensionHelperViolations(
        relativePath: _worldFileRel,
        source:
            'Iterable<Object> allProvinces(WorldState world) { '
            'return world.allProvinces(); }',
      );
      expect(violations, isEmpty);
    });

    test('flags a re-rolled inline dual-region body', () {
      final violations = findWorldDuplicateExtensionHelperViolations(
        relativePath: _worldFileRel,
        source:
            'Iterable<Object> allProvinces(WorldState world) sync* { '
            'yield* world.oldWorld.provinces; '
            'yield* world.newWorld.provinces; }',
      );
      expect(violations, hasLength(1));
      expect(violations.single.symbol, 'allProvinces');
    });

    test('flags a body that calls a different method (not delegation)', () {
      final violations = findWorldDuplicateExtensionHelperViolations(
        relativePath: _worldFileRel,
        source:
            'Iterable<Object> allProvinces(WorldState world) => '
            'world.somethingElse();',
      );
      expect(violations, hasLength(1));
    });

    test('flags a block delegator with extra statements', () {
      final violations = findWorldDuplicateExtensionHelperViolations(
        relativePath: _worldFileRel,
        source:
            'Iterable<Object> allProvinces(WorldState world) { '
            'final x = world.allProvinces(); return x; }',
      );
      expect(violations, hasLength(1));
    });

    test('ignores top-level functions outside the watched name set', () {
      final violations = findWorldDuplicateExtensionHelperViolations(
        relativePath: _worldFileRel,
        source:
            'Iterable<Object> someOtherHelper(WorldState world) sync* { '
            'yield* world.oldWorld.provinces; }',
      );
      expect(violations, isEmpty);
    });

    test('ignores files outside the world lib prefix', () {
      final violations = findWorldDuplicateExtensionHelperViolations(
        relativePath: 'packages/colonizethis_logic/lib/src/sample.dart',
        source:
            'Iterable<Object> allProvinces(WorldState world) sync* { '
            'yield* world.oldWorld.provinces; }',
      );
      expect(violations, isEmpty);
    });
  });

  test('allProvinces is in the watched name set', () {
    expect(worldDuplicateExtensionHelperNames, contains('allProvinces'));
  });

  test('current repo passes the duplicate-extension-helper gate', () {
    expect(runCheckWorldNoDuplicateExtensionHelper('.', info: (_) {}), 0);
  });

  test('fails when a duplicate top-level allProvinces is reintroduced', () {
    final temp = Directory.systemTemp.createTempSync('world_dup_ext_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final srcDir = Directory(
      p.join(temp.path, 'packages/colonizethis_world/lib/src/world'),
    )..createSync(recursive: true);
    File(p.join(srcDir.path, 'offender.dart'))
      ..createSync()
      ..writeAsStringSync(
        'Iterable<Object> allProvinces(dynamic world) sync* { '
        'yield* world.oldWorld.provinces; '
        'yield* world.newWorld.provinces; }',
      );

    expect(
      runCheckWorldNoDuplicateExtensionHelper(temp.path, info: (_) {}),
      1,
    );
  });

  test('passes when the top-level allProvinces only delegates', () {
    final temp = Directory.systemTemp.createTempSync('world_dup_ext_ok_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final srcDir = Directory(
      p.join(temp.path, 'packages/colonizethis_world/lib/src/world'),
    )..createSync(recursive: true);
    File(p.join(srcDir.path, 'delegator.dart'))
      ..createSync()
      ..writeAsStringSync(
        'Iterable<Object> allProvinces(dynamic world) => '
        'world.allProvinces();',
      );

    expect(
      runCheckWorldNoDuplicateExtensionHelper(temp.path, info: (_) {}),
      0,
    );
  });
}
