/// Pins Phase-5/6 topic splits for S7-D findings + orchestrator support
/// (Refs #3972 AC3 / AC4; #3977 AC4).
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

  group('s7d diagnostic orchestration shrink (Refs #3977 AC4)', () {
    test('diagnostic contract is orchestration-only and under 800 lines', () {
      final contract = File(
        p.join(
          packageRoot,
          'test',
          'seed42_observer_conquest_s7d_diagnostic_test.dart',
        ),
      );
      final lines = contract.readAsLinesSync();
      expect(lines.length, lessThanOrEqualTo(800));
      final source = contract.readAsStringSync();
      expect(source, contains('runSeed42S7dDiagnosticCampaign'));
      expect(source, isNot(contains('runSeed42ObserverCampaign(')));
      expect(source, isNot(contains('S7D_DIAGNOSTIC_JSON_BEGIN')));
    });

    test('campaign runner lives under support/s7d', () {
      expect(
        File(
          p.join(s7dDir.path, 'run_seed42_s7d_diagnostic_campaign.dart'),
        ).existsSync(),
        isTrue,
      );
    });

    test('feedstock helper unit tests live under support_test/', () {
      expect(
        File(
          p.join(
            packageRoot,
            'test',
            'support_test',
            'seed42_s7d_feedstock_helpers_test.dart',
          ),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(
            packageRoot,
            'test',
            'seed42_s7d_feedstock_helpers_test.dart',
          ),
        ).existsSync(),
        isFalse,
      );
    });
  });
}
