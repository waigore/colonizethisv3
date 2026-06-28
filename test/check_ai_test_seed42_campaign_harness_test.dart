import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_test_seed42_campaign_harness.dart';

/// Minimal inline seed-42 observer campaign body (the pattern the gate
/// forbids in new test files): seed-42 init literal + trusted-order resolve.
const String _inlineCampaignBody =
    "import 'package:test/test.dart';\n\n"
    'void main() {\n'
    '  test(\'campaign\', () {\n'
    '    final init = runInitGame(config: GameSetupConfig(seed: 42));\n'
    '    final result = validateOrdersAndResolveTurnFromTrustedOrders(\n'
    '      game: init.game,\n'
    '    );\n'
    '    expect(result, isNotNull);\n'
    '  });\n'
    '}\n';

void main() {
  group('runCheckAiTestSeed42CampaignHarness', () {
    test(
      'fails on a new inline seed-42 campaign loop outside the allowlist',
      () {
        final temp = Directory.systemTemp.createTempSync('ai-seed42-new-');
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
            p.join(planning.path, 'seed42_new_campaign_test.dart'),
            _inlineCampaignBody,
          );

          final errors = <String>[];
          final exitCode = runCheckAiTestSeed42CampaignHarness(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('runSeed42ObserverCampaign'));
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test('passes when the test delegates to the shared harness', () {
      final temp = Directory.systemTemp.createTempSync('ai-seed42-harness-');
      try {
        final aiTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiTest.path, 'seed42_harness_user_test.dart'),
          "import 'package:test/test.dart';\n\n"
          'void main() {\n'
          '  final r = runSeed42ObserverCampaign(turns: 1);\n'
          '  expect(r.finalGame, isNotNull);\n'
          '}\n',
        );

        final exitCode = runCheckAiTestSeed42CampaignHarness(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when seed-42 init has no trusted-order resolve loop', () {
      final temp = Directory.systemTemp.createTempSync('ai-seed42-noloop-');
      try {
        final aiTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiTest.path, 'seed42_probe_only_test.dart'),
          "import 'package:test/test.dart';\n\n"
          'void main() {\n'
          '  final init = runInitGame(config: GameSetupConfig(seed: 42));\n'
          '  expect(init.game, isNotNull);\n'
          '}\n',
        );

        final exitCode = runCheckAiTestSeed42CampaignHarness(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores inline campaigns outside the ai package test tree', () {
      final temp = Directory.systemTemp.createTempSync('ai-seed42-other-');
      try {
        final ordersTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersTest.path, 'seed42_inline_test.dart'),
          _inlineCampaignBody,
        );

        final exitCode = runCheckAiTestSeed42CampaignHarness(
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

  group('aiTestSeed42HarnessViolationReason', () {
    test('flags a new inline campaign test file', () {
      expect(
        aiTestSeed42HarnessViolationReason(
          'packages/colonizethis_ai/test/seed42_brand_new_test.dart',
          _inlineCampaignBody,
        ),
        isNotNull,
      );
    });

    test('does not flag an allowlisted grandfathered campaign', () {
      final allowlisted = seed42CampaignHarnessAllowlist.first;
      expect(
        aiTestSeed42HarnessViolationReason(allowlisted, _inlineCampaignBody),
        isNull,
      );
    });

    test('does not flag a harness-delegating test', () {
      expect(
        aiTestSeed42HarnessViolationReason(
          'packages/colonizethis_ai/test/seed42_uses_harness_test.dart',
          'void main() => runSeed42ObserverCampaign(turns: 1);',
        ),
        isNull,
      );
    });

    test('does not flag the shared harness support file itself', () {
      expect(
        aiTestSeed42HarnessPathInScope(
          'packages/colonizethis_ai/test/support/seed42_observer_campaign.dart',
        ),
        isFalse,
      );
    });
  });

  group('seed42CampaignHarnessAllowlist integrity', () {
    test('every allowlisted path still exists on disk', () {
      final repoRoot = Directory.current.path;
      for (final rel in seed42CampaignHarnessAllowlist) {
        expect(
          File(p.join(repoRoot, rel)).existsSync(),
          isTrue,
          reason:
              'Allowlisted seed-42 campaign $rel no longer exists; remove the '
              'stale allowlist entry once the file is migrated/deleted.',
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
