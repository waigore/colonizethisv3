/// Pins Phase-5 topic splits for S7-D findings + orchestrator support
/// (Refs #3972 AC3 / AC4).
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  final packageRoot = Directory.current.path;
  final s7dDir = Directory(p.join(packageRoot, 'test', 'support', 's7d'));
  final supportDir = Directory(p.join(packageRoot, 'test', 'support'));

  group('s7d diagnostic findings topic split (Refs #3972 AC3)', () {
    test('barrel exports topic modules and keeps findings anchor', () {
      final barrel = File(
        p.join(s7dDir.path, 's7d_diagnostic_findings.dart'),
      ).readAsStringSync();
      expect(barrel, contains("export 's7d_findings_geography.dart';"));
      expect(barrel, contains("export 's7d_findings_feedstock_extraction.dart';"));
      expect(barrel, contains("export 's7d_findings_feedstock_castiron.dart';"));
      expect(barrel, contains("export 's7d_findings_lock_recovery.dart';"));
      expect(
        barrel,
        contains('typedef Seed42S7dDiagnosticFindingsAnchor = void;'),
      );
    });

    test('no s7d findings support file exceeds 1000 physical lines', () {
      final findingsFiles = s7dDir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                p.basename(f.path).startsWith('s7d_findings_') ||
                p.basename(f.path) == 's7d_diagnostic_findings.dart',
          )
          .toList();
      expect(findingsFiles, isNotEmpty);
      for (final file in findingsFiles) {
        final lines = file.readAsLinesSync().length;
        expect(
          lines,
          lessThanOrEqualTo(1000),
          reason: '${p.basename(file.path)} has $lines physical lines',
        );
      }
    });

    test('negative: monolithic findings god-file is gone', () {
      // The pre-split monolith was a single ~1667-line findings library.
      // After the split, no single findings topic file may re-absorb that size.
      final oversized = <String>[];
      for (final file in s7dDir.listSync().whereType<File>()) {
        final name = p.basename(file.path);
        if (!name.startsWith('s7d_findings_') &&
            name != 's7d_diagnostic_findings.dart') {
          continue;
        }
        final lines = file.readAsLinesSync().length;
        if (lines > 1000) {
          oversized.add('$name ($lines)');
        }
      }
      expect(oversized, isEmpty);
    });
  });

  group('orchestrator test support topic split (Refs #3972 AC4)', () {
    test('barrel is thin and re-exports topical scenario libraries', () {
      final barrelPath = p.join(
        supportDir.path,
        'domain_planner_orchestrator_test_support.dart',
      );
      final barrel = File(barrelPath).readAsStringSync();
      expect(
        barrel,
        contains("export 'domain_planner_orchestrator_quota_consts.dart';"),
      );
      expect(
        barrel,
        contains("export 'domain_planner_orchestrator_expand_scenarios.dart';"),
      );
      expect(
        barrel,
        contains(
          "export 'domain_planner_orchestrator_colonial_lite_scenarios.dart';",
        ),
      );
      expect(
        barrel,
        contains(
          "export 'domain_planner_orchestrator_spy_trade_scenarios.dart';",
        ),
      );
      expect(
        barrel,
        contains("export 'domain_planner_orchestrator_runners.dart';"),
      );
      expect(
        File(barrelPath).readAsLinesSync().length,
        lessThan(40),
        reason: 'orchestrator support barrel must stay thin',
      );
    });

    test('topical orchestrator support libraries exist', () {
      for (final name in <String>[
        'domain_planner_orchestrator_quota_consts.dart',
        'domain_planner_orchestrator_expand_scenarios.dart',
        'domain_planner_orchestrator_colonial_lite_scenarios.dart',
        'domain_planner_orchestrator_spy_trade_scenarios.dart',
        'domain_planner_orchestrator_runners.dart',
      ]) {
        expect(
          File(p.join(supportDir.path, name)).existsSync(),
          isTrue,
          reason: 'missing topical library $name',
        );
      }
    });

    test('negative: quota consts are not redeclared in the barrel', () {
      final barrel = File(
        p.join(
          supportDir.path,
          'domain_planner_orchestrator_test_support.dart',
        ),
      ).readAsStringSync();
      expect(barrel.contains('kGp1OwProvincesBelowQuota'), isFalse);
      expect(barrel.contains('Game buildOrchestrator'), isFalse);
    });
  });
}
