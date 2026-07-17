import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_ownership_paint.dart';

void main() {
  group('findSetupDedupOwnershipPaintViolations', () {
    const paint =
        'packages/colonizethis_setup/lib/src/setup/'
        'game_setup_ownership_paint.dart';
    const ownership =
        'packages/colonizethis_setup/lib/src/setup/game_setup_ownership.dart';
    const remainder =
        'packages/colonizethis_setup/lib/src/setup/'
        'game_setup_ownership_remainder_factions.dart';

    test('flags direct locked assigner call in ownership orchestration', () {
      const src = '''
Map<String, String> f() {
  return assignTerritoriesLockedOnLandmass(
    landmassProvinceIds: {},
    neighbours: {},
    growthOrder: [],
    targetPerFaction: {},
  );
}
''';
      final violations = findSetupDedupOwnershipPaintViolations(
        sourcesByPath: {
          paint: 'Map<String, String> _paintLandmass() => {};\n',
          ownership: src,
        },
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.message.contains('LockedOnLandmass')),
        isTrue,
      );
    });

    test('flags direct BFS assigner call in remainder scaffolding', () {
      const src = '''
Map<String, String> f() {
  return assignTerritoriesByBfsGrowth(
    neighbours: {},
    factionIds: [],
    seeds: {},
    targetPerFaction: {},
    available: {},
  );
}
''';
      final violations = findSetupDedupOwnershipPaintViolations(
        sourcesByPath: {
          paint: 'Map<String, String> _paintLandmass() => {};\n',
          remainder: src,
        },
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.message.contains('ByBfsGrowth')),
        isTrue,
      );
    });

    test('flags _lockedGrowthOrder outside the paint facade', () {
      const src = '''
List<String> _lockedGrowthOrder(List<String> ids, Map<String, int> t) => ids;
''';
      final violations = findSetupDedupOwnershipPaintViolations(
        sourcesByPath: {
          paint: 'Map<String, String> _paintLandmass() => {};\n',
          remainder: src,
        },
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.message.contains('_lockedGrowthOrder')),
        isTrue,
      );
    });

    test('exempts paint facade and assigner definitions', () {
      const paintSrc = '''
List<String> _lockedGrowthOrder(List<String> ids, Map<String, int> t) => ids;
Map<String, String> _paintLandmass() {
  return assignTerritoriesLockedOnLandmass(
    landmassProvinceIds: {},
    neighbours: {},
    growthOrder: [],
    targetPerFaction: {},
  );
}
''';
      const lockedSrc = '''
Map<String, String> assignTerritoriesLockedOnLandmass({
  required Set<String> landmassProvinceIds,
  required Map<String, Set<String>> neighbours,
  required List<String> growthOrder,
  required Map<String, int> targetPerFaction,
}) => {};
''';
      final violations = findSetupDedupOwnershipPaintViolations(
        sourcesByPath: {
          paint: paintSrc,
          'packages/colonizethis_setup/lib/src/setup/'
                  'locked_province_assigner.dart':
              lockedSrc,
        },
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final code = runCheckSetupDedupOwnershipPaint(
        _repoRoot(),
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
