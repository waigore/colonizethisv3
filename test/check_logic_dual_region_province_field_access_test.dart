import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_dual_region_province_field_access.dart';

void main() {
  test('scan root targets colonizethis_world after package split', () {
    expect(
      logicDualRegionProvinceFieldAccessScanDirForTests(),
      'packages/colonizethis_world/lib/src',
    );
  });
  group('logicDualRegionProvinceFieldAccessLineMatches', () {
    test('matches oldWorld.provinces', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'for (final p in game.worldState.oldWorld.provinces) {',
        ),
        isTrue,
      );
    });

    test('matches newWorld.provinces', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'game.worldState.newWorld.provinces',
        ),
        isTrue,
      );
    });

    test('matches oldWorld.units', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'for (final u in game.worldState.oldWorld.units) {',
        ),
        isTrue,
      );
    });

    test('matches newWorld.units', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'game.worldState.newWorld.units',
        ),
        isTrue,
      );
    });

    test('matches manual regionId old-world branching', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'if (regionId == kRegionOldWorld) {',
        ),
        isTrue,
      );
    });

    test('ignores allProvinces', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'for (final p in allProvinces(game.worldState)) {',
        ),
        isFalse,
      );
    });

    test('ignores allUnits', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'for (final u in allUnits(game.worldState)) {',
        ),
        isFalse,
      );
    });
  });

  test('current repo passes dual-region province field access gate', () {
    expect(runCheckLogicDualRegionProvinceFieldAccess('.', info: (_) {}), 0);
  });

  test('fails when a world src file uses oldWorld.provinces outside canonical lookups', () {
    final temp = Directory.systemTemp.createTempSync('world_dual_region_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final srcDir = Directory(
      p.join(temp.path, 'packages/colonizethis_world/lib/src/world'),
    )..createSync(recursive: true);
    File(p.join(srcDir.path, 'offender.dart'))
      ..createSync()
      ..writeAsStringSync(
        "void scanMe(dynamic ws) { for (final p in ws.oldWorld.provinces) {} }",
      );

    expect(
      runCheckLogicDualRegionProvinceFieldAccess(temp.path, info: (_) {}),
      1,
    );
  });

  test('fails when the colonizethis_world lib/src tree is missing', () {
    final temp = Directory.systemTemp.createTempSync('world_dual_region_missing_');
    addTearDown(() => temp.deleteSync(recursive: true));

    expect(
      runCheckLogicDualRegionProvinceFieldAccess(temp.path, info: (_) {}),
      1,
    );
  });
}
