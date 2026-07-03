import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_test_soft_weight_contract.dart';

/// Minimal parameterized-contract test body stand-in (content is irrelevant to
/// this gate — it keys purely off the reserved filename suffix).
const String _contractBody =
    "import 'package:test/test.dart';\n\n"
    'void main() {\n'
    "  test('contract', () {\n"
    '    expect(1, 1);\n'
    '  });\n'
    '}\n';

void main() {
  group('runCheckAiTestSoftWeightContract', () {
    test(
      'fails on a new *soft_weight_wiring_test.dart file outside the allowlist',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-softweight-new-');
        try {
          final planning = Directory(
            p.join(
              temp.path,
              'packages',
              'colonizethis_ai',
              'test',
              'planning',
            ),
          )..createSync(recursive: true);
          _writeDartFile(
            p.join(
              planning.path,
              'phase_planner_brand_new_soft_weight_wiring_test.dart',
            ),
            _contractBody,
          );

          final errors = <String>[];
          final exitCode = runCheckAiTestSoftWeightContract(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('parameterized'));
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test(
      'passes when only the allowlisted parameterized contract files use the '
      'suffix',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-softweight-ok-');
        try {
          final planning = Directory(
            p.join(
              temp.path,
              'packages',
              'colonizethis_ai',
              'test',
              'planning',
            ),
          )..createSync(recursive: true);
          for (final rel in softWeightContractAllowlist) {
            _writeDartFile(p.join(temp.path, rel), _contractBody);
          }
          // A behavioural pin that does NOT use the reserved suffix is allowed.
          _writeDartFile(
            p.join(
              planning.path,
              'phase_planner_economy_build_pick_cargo_bonus_test.dart',
            ),
            _contractBody,
          );

          final exitCode = runCheckAiTestSoftWeightContract(
            temp.path,
            info: (_) {},
            err: (_) {},
          );
          expect(exitCode, 0);
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test('ignores soft_weight_wiring files outside the AI package test tree', () {
      final temp = Directory.systemTemp.createTempSync('ai-softweight-other-');
      try {
        final ordersTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersTest.path, 'something_soft_weight_wiring_test.dart'),
          _contractBody,
        );

        final exitCode = runCheckAiTestSoftWeightContract(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('aiTestSoftWeightContractViolationReason', () {
    test('flags a new clone outside the allowlist', () {
      expect(
        aiTestSoftWeightContractViolationReason(
          'packages/colonizethis_ai/test/planning/phase_planner_new_soft_weight_wiring_test.dart',
        ),
        isNotNull,
      );
    });

    test('does not flag an allowlisted parameterized contract file', () {
      final allowlisted = softWeightContractAllowlist.first;
      expect(
        aiTestSoftWeightContractViolationReason(allowlisted),
        isNull,
      );
    });

    test('does not flag a behavioural pin using a different suffix', () {
      expect(
        aiTestSoftWeightContractViolationReason(
          'packages/colonizethis_ai/test/planning/phase_planner_goal_filter_colonial_pressure_test.dart',
        ),
        isNull,
      );
    });
  });

  group('softWeightContractAllowlist integrity', () {
    test('every allowlisted path still exists on disk', () {
      final repoRoot = Directory.current.path;
      for (final rel in softWeightContractAllowlist) {
        expect(
          File(p.join(repoRoot, rel)).existsSync(),
          isTrue,
          reason:
              'Allowlisted soft-weight contract file $rel no longer exists; '
              'update the allowlist when consolidating/renaming the contract '
              'tests.',
        );
      }
    });
  });
}

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
