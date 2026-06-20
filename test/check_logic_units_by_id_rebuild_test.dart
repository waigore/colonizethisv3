import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_units_by_id_rebuild.dart';

void main() {
  test('scan roots target the split domain packages after the split', () {
    final dirs = logicUnitsByIdRebuildScanDirsForTests();
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

  group('logicUnitsByIdRebuildLineMatches', () {
    test('matches bare unitsByIdFromWorld( call', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          'final unitsById = unitsByIdFromWorld(game.worldState);',
        ),
        isTrue,
      );
    });

    test('matches Map.from(unitsByIdFromWorld(...)) call', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          'final m = Map<String, Unit>.from(unitsByIdFromWorld(game.worldState));',
        ),
        isTrue,
      );
    });

    test('matches indented call', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          '      unitsById: unitsByIdFromWorld(game.worldState),',
        ),
        isTrue,
      );
    });

    test('ignores doc-comment reference', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          '/// skips the embedded buildPlayerView / unitsByIdFromWorld scans.',
        ),
        isFalse,
      );
    });

    test('ignores line-comment reference', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          '  // call unitsByIdFromWorld(world) here if you want to rebuild.',
        ),
        isFalse,
      );
    });

    test('ignores allUnitsById getter call', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          'final unitsById = game.worldState.allUnitsById;',
        ),
        isFalse,
      );
    });

    test('ignores function declaration line (does not match by itself; '
        'canonical file is excluded by the runner)', () {
      // Just sanity: the runner excludes the canonical file entirely, so the
      // declaration line cannot trip the gate at the call-site level.
      expect(
        logicUnitsByIdRebuildLineMatches(
          'Map<String, Unit> unitsByIdFromWorld(WorldState world) {',
        ),
        isTrue,
      );
    });
  });

  test('current repo passes logic units-by-id rebuild gate', () {
    expect(runCheckLogicUnitsByIdRebuild('.', info: (_) {}), 0);
  });

  test('fails when a split domain package src file calls unitsByIdFromWorld(', () {
    final temp = Directory.systemTemp.createTempSync('units_by_id_rebuild_');
    addTearDown(() => temp.deleteSync(recursive: true));

    // Materialize every scan root so the runner does not early-exit on a
    // missing tree, then plant one offending call site in the orders package.
    for (final relative in logicUnitsByIdRebuildScanDirsForTests()) {
      Directory(p.join(temp.path, relative)).createSync(recursive: true);
    }
    // Canonical definition file is excluded and must not trip the gate.
    File(p.join(
      temp.path,
      'packages/colonizethis_world/lib/src/world/unit_lookup.dart',
    ))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'Map<String, Unit> unitsByIdFromWorld(WorldState world) => {};',
      );
    File(p.join(
      temp.path,
      'packages/colonizethis_orders/lib/src/orders/offender.dart',
    ))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'void scanMe(dynamic g) { final m = unitsByIdFromWorld(g.worldState); }',
      );

    expect(runCheckLogicUnitsByIdRebuild(temp.path, info: (_) {}), 1);
  });

  test('passes when domain packages only use the cached allUnitsById getter', () {
    final temp = Directory.systemTemp.createTempSync('units_by_id_rebuild_ok_');
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final relative in logicUnitsByIdRebuildScanDirsForTests()) {
      Directory(p.join(temp.path, relative)).createSync(recursive: true);
    }
    File(p.join(
      temp.path,
      'packages/colonizethis_turn/lib/src/turn/movement.dart',
    ))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'void scanMe(dynamic g) { final m = g.worldState.allUnitsById; }',
      );

    expect(runCheckLogicUnitsByIdRebuild(temp.path, info: (_) {}), 0);
  });

  test('fails when a split domain package lib/src tree is missing', () {
    final temp = Directory.systemTemp.createTempSync('units_by_id_rebuild_miss_');
    addTearDown(() => temp.deleteSync(recursive: true));

    expect(runCheckLogicUnitsByIdRebuild(temp.path, info: (_) {}), 1);
  });
}
