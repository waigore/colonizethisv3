import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_dual_region_province_field_access.dart';

void main() {
  test('scan roots target the split domain packages after the split', () {
    final dirs = logicDualRegionProvinceFieldAccessScanDirsForTests();
    expect(
      dirs,
      containsAll(<String>[
        'packages/colonizethis_world/lib/src',
        'packages/colonizethis_combat/lib/src',
        'packages/colonizethis_economy/lib/src',
        'packages/colonizethis_diplomacy/lib/src',
        'packages/colonizethis_setup/lib/src',
        'packages/colonizethis_orders/lib/src',
        'packages/colonizethis_turn/lib/src',
        'packages/colonizethis_ai_contracts/lib/src',
        'packages/colonizethis_logic/lib/src',
      ]),
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

  test('fails when a non-world split package src file uses oldWorld.provinces', () {
    final temp = Directory.systemTemp.createTempSync('dual_region_');
    addTearDown(() => temp.deleteSync(recursive: true));

    // Materialize every scan root so the runner does not early-exit on a
    // missing tree, then plant one offending access in the setup package — a
    // tree the prior world-only scan root would have silently ignored.
    for (final relative in logicDualRegionProvinceFieldAccessScanDirsForTests()) {
      Directory(p.join(temp.path, relative)).createSync(recursive: true);
    }
    File(p.join(
      temp.path,
      'packages/colonizethis_setup/lib/src/setup/offender.dart',
    ))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'void scanMe(dynamic ws) { for (final p in ws.oldWorld.provinces) {} }',
      );

    expect(
      runCheckLogicDualRegionProvinceFieldAccess(temp.path, info: (_) {}),
      1,
    );
  });

  test('fails when the orders package reintroduces manual region branching', () {
    final temp = Directory.systemTemp.createTempSync('dual_region_orders_');
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final relative in logicDualRegionProvinceFieldAccessScanDirsForTests()) {
      Directory(p.join(temp.path, relative)).createSync(recursive: true);
    }
    File(p.join(
      temp.path,
      'packages/colonizethis_orders/lib/src/orders/orders_application.dart',
    ))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'void scanMe(String regionId, dynamic ws) {\n'
        '  if (regionId == kRegionOldWorld) {\n'
        '    ws.copyWith(oldWorld: ws.oldWorld);\n'
        '  }\n'
        '}',
      );

    expect(
      runCheckLogicDualRegionProvinceFieldAccess(temp.path, info: (_) {}),
      1,
    );
  });

  test('passes when split packages only use canonical allProvinces/allUnits', () {
    final temp = Directory.systemTemp.createTempSync('dual_region_ok_');
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final relative in logicDualRegionProvinceFieldAccessScanDirsForTests()) {
      Directory(p.join(temp.path, relative)).createSync(recursive: true);
    }
    File(p.join(
      temp.path,
      'packages/colonizethis_turn/lib/src/turn/movement.dart',
    ))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'void scanMe(dynamic ws) { for (final p in allProvinces(ws)) {} }',
      );

    expect(
      runCheckLogicDualRegionProvinceFieldAccess(temp.path, info: (_) {}),
      0,
    );
  });

  test('does not flag the canonical world lookup definition files', () {
    final temp = Directory.systemTemp.createTempSync('dual_region_canonical_');
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final relative in logicDualRegionProvinceFieldAccessScanDirsForTests()) {
      Directory(p.join(temp.path, relative)).createSync(recursive: true);
    }
    File(p.join(
      temp.path,
      'packages/colonizethis_world/lib/src/world/province_lookup.dart',
    ))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'Iterable get all => [...oldWorld.provinces, ...newWorld.provinces];',
      );

    expect(
      runCheckLogicDualRegionProvinceFieldAccess(temp.path, info: (_) {}),
      0,
    );
  });

  test('fails when a split domain package lib/src tree is missing', () {
    final temp = Directory.systemTemp.createTempSync('dual_region_missing_');
    addTearDown(() => temp.deleteSync(recursive: true));

    expect(
      runCheckLogicDualRegionProvinceFieldAccess(temp.path, info: (_) {}),
      1,
    );
  });
}
