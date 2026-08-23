import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_lib_unit_lookup_sot.dart';

void main() {
  group('worldLibUnitLookupSotLineMatches', () {
    test('matches a call site', () {
      expect(
        worldLibUnitLookupSotLineMatches(
          'for (final u in allUnitsFromWorld(ws)) {',
        ),
        isTrue,
      );
    });

    test('ignores comments', () {
      expect(
        worldLibUnitLookupSotLineMatches('/// allUnitsFromWorld(world)'),
        isFalse,
      );
      expect(
        worldLibUnitLookupSotLineMatches('  // allUnitsFromWorld(ws)'),
        isFalse,
      );
    });

    test('ignores allUnitsById iteration', () {
      expect(
        worldLibUnitLookupSotLineMatches(
          'for (final u in ws.allUnitsById.values) {',
        ),
        isFalse,
      );
    });
  });

  test('current repo passes world lib unit-lookup SoT gate', () {
    expect(runCheckWorldLibUnitLookupSot('.', info: (_) {}), 0);
  });

  test(
    'fails when a world lib file other than unit_lookup calls allUnitsFromWorld(',
    () {
      final temp = Directory.systemTemp.createTempSync('world_unit_sot_');
      addTearDown(() => temp.deleteSync(recursive: true));
      Directory(
        p.join(temp.path, 'packages/colonizethis_world/lib/src/world'),
      ).createSync(recursive: true);
      File(
        p.join(
          temp.path,
          'packages/colonizethis_world/lib/src/world/unit_lookup.dart',
        ),
      ).writeAsStringSync('List allUnitsFromWorld(dynamic w) => [];');
      File(
        p.join(
          temp.path,
          'packages/colonizethis_world/lib/src/world/army_migration.dart',
        ),
      ).writeAsStringSync('void f(dynamic w) { allUnitsFromWorld(w); }');

      expect(runCheckWorldLibUnitLookupSot(temp.path, info: (_) {}), 1);
    },
  );

  test('does not flag other packages that still call allUnitsFromWorld', () {
    final temp = Directory.systemTemp.createTempSync('world_unit_sot_other_');
    addTearDown(() => temp.deleteSync(recursive: true));
    Directory(
      p.join(temp.path, 'packages/colonizethis_world/lib/src/world'),
    ).createSync(recursive: true);
    Directory(
      p.join(temp.path, 'packages/colonizethis_combat/lib/src'),
    ).createSync(recursive: true);
    File(
      p.join(
        temp.path,
        'packages/colonizethis_world/lib/src/world/unit_lookup.dart',
      ),
    ).writeAsStringSync('List allUnitsFromWorld(dynamic w) => [];');
    File(
      p.join(temp.path, 'packages/colonizethis_combat/lib/src/offender.dart'),
    ).writeAsStringSync('void f(dynamic w) { allUnitsFromWorld(w); }');

    expect(runCheckWorldLibUnitLookupSot(temp.path, info: (_) {}), 0);
  });

  test('fails when the world lib tree is missing', () {
    final temp = Directory.systemTemp.createTempSync('world_unit_sot_miss_');
    addTearDown(() => temp.deleteSync(recursive: true));
    expect(runCheckWorldLibUnitLookupSot(temp.path, info: (_) {}), 1);
  });
}
