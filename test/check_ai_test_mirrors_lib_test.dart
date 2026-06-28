import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_test_mirrors_lib.dart';

void main() {
  group('runCheckAiTestMirrorsLib', () {
    test('fails when a unit _test.dart lives flat at the test root', () {
      final temp = Directory.systemTemp.createTempSync('ai-mirror-flat-');
      try {
        final aiTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiTest.path, 'war_desire_score_test.dart'),
          "import 'package:test/test.dart';\nvoid main() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAiTestMirrorsLib(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('war_desire_score_test.dart'));
        expect(errors.join('\n'), contains('lives directly in `test/`'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when the unit test mirrors its lib/src subtree', () {
      final temp = Directory.systemTemp.createTempSync('ai-mirror-nested-');
      try {
        final aiTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiTest.path, 'planning', 'war_desire_score_test.dart'),
          "import 'package:test/test.dart';\nvoid main() {}\n",
        );

        final exitCode = runCheckAiTestMirrorsLib(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes for an allowlisted flat integration test', () {
      final temp = Directory.systemTemp.createTempSync('ai-mirror-allow-');
      try {
        final aiTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiTest.path, 'seed42_gp4_war_focus_test.dart'),
          "import 'package:test/test.dart';\nvoid main() {}\n",
        );

        final exitCode = runCheckAiTestMirrorsLib(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores non-test scaffolding helpers at the test root', () {
      final temp = Directory.systemTemp.createTempSync('ai-mirror-support-');
      try {
        final aiTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiTest.path, 'planner_test_helpers.dart'),
          "import 'package:test/test.dart';\n",
        );

        final exitCode = runCheckAiTestMirrorsLib(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores tests outside the ai package test tree', () {
      final temp = Directory.systemTemp.createTempSync('ai-mirror-other-');
      try {
        final ordersTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersTest.path, 'loose_test.dart'),
          "import 'package:test/test.dart';\nvoid main() {}\n",
        );

        final exitCode = runCheckAiTestMirrorsLib(
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

  group('aiTestMirrorsLibViolationReason', () {
    test('flags a flat-root unit test', () {
      expect(
        aiTestMirrorsLibViolationReason(
          'packages/colonizethis_ai/test/tactical_ai_test.dart',
        ),
        isNotNull,
      );
    });

    test('does not flag a nested mirrored test', () {
      expect(
        aiTestMirrorsLibViolationReason(
          'packages/colonizethis_ai/test/tactical/tactical_ai_test.dart',
        ),
        isNull,
      );
    });

    test('does not flag an allowlisted flat test', () {
      expect(
        aiTestMirrorsLibViolationReason(
          'packages/colonizethis_ai/test/ai_config_test.dart',
        ),
        isNull,
      );
    });

    test('does not flag a non-test scaffolding file at the root', () {
      expect(
        aiTestMirrorsLibViolationReason(
          'packages/colonizethis_ai/test/planner_test_helpers.dart',
        ),
        isNull,
      );
    });

    test('does not flag files outside the ai package', () {
      expect(
        aiTestMirrorsLibViolationReason(
          'packages/colonizethis_orders/test/loose_test.dart',
        ),
        isNull,
      );
    });
  });

  group('aiTestMirrorsLibPathInScope', () {
    test('matches ai package test paths only', () {
      expect(
        aiTestMirrorsLibPathInScope(
          'packages/colonizethis_ai/test/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        aiTestMirrorsLibPathInScope(
          'packages/colonizethis_ai/lib/src/planning/foo.dart',
        ),
        isFalse,
      );
    });
  });
}

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
