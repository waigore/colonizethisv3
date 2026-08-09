import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_unit_spawn.dart';

void main() {
  group('findSetupDedupUnitSpawnViolations', () {
    const canonicalPath =
        'packages/colonizethis_setup/lib/src/setup/setup_unit_spawn.dart';
    const bootstrapPath =
        'packages/colonizethis_setup/lib/src/setup/game_setup_helpers_bootstrap.dart';
    const advancedPath =
        'packages/colonizethis_setup/lib/src/setup/advanced_start_bootstrap_units.dart';

    test('flags private spawn/merge clone names', () {
      const src = '''
void _spawnCivilianUnitsOfType({required String ownerId}) {}
''';
      final violations = findSetupDedupUnitSpawnViolations(
        sourcesByPath: const {bootstrapPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('Private spawn/merge'));
    });

    test('flags mintShipInstances outside shared module', () {
      const src = '''
final (seqAfter, newInstances) = mintShipInstances(
  nextShipInstanceSeq: nextSeq,
  typeIds: typeIds,
);
''';
      final violations = findSetupDedupUnitSpawnViolations(
        sourcesByPath: const {advancedPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('mergeHomeFleetShips'));
    });

    test('flags capital tileKey Unit spawn outside shared module', () {
      const src = '''
destination.add(Unit(
  id: id,
  type: unitType,
  ownerId: ownerId,
  locationProvinceId: capitalProvinceId,
  status: UnitStatus.idle,
  tileKey: capitalTileKey,
));
''';
      final violations = findSetupDedupUnitSpawnViolations(
        sourcesByPath: const {bootstrapPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('spawnCivilianUnitsOfType'));
    });

    test('accepts shared helper call sites', () {
      const src = '''
spawnCivilianUnitsOfType(
  unitsByRegion: unitsByRegion,
  ownerId: ownerId,
  capitalProvinceId: capitalProvinceId,
  capitalTileKey: capitalTileKey,
  capitalRegionId: capitalRegionId,
  unitType: entry.key,
  count: entry.value,
  unitIdFor: baseSetupCivilianUnitId,
);
nextSeq = mergeHomeFleetShips(
  ownerId: player.id,
  regionId: regionId,
  localProvinceId: localProvinceId,
  shipCount: shipCount,
  shipTypeId: shipTypeId,
  fleets: fleets,
  fleetIndexById: fleetIndexById,
  nextSeq: nextSeq,
  appendExistingShips: true,
);
''';
      final violations = findSetupDedupUnitSpawnViolations(
        sourcesByPath: const {bootstrapPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts the canonical setup_unit_spawn module', () {
      const src = '''
void _spawnCivilianUnitsOfType() {}
final r = mintShipInstances(nextShipInstanceSeq: 1, typeIds: const []);
tileKey: capitalTileKey,
''';
      final violations = findSetupDedupUnitSpawnViolations(
        sourcesByPath: const {canonicalPath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores comment lines', () {
      const src = '''
// void _spawnCivilianUnitsOfType() {}
/// Avoid mintShipInstances( outside setup_unit_spawn.
// tileKey: capitalTileKey,
''';
      final violations = findSetupDedupUnitSpawnViolations(
        sourcesByPath: const {advancedPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckSetupDedupUnitSpawn(
        repoRoot,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final manifest = File(
      p.join(dir.path, 'tool', 'ct_repo_lint_manifest.yaml'),
    );
    if (manifest.existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
