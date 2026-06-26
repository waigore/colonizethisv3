import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_test_no_duplicate_scaffolding.dart';

void main() {
  group('runCheckAiTestNoDuplicateScaffolding', () {
    test('fails when a _test.dart lives inside test/support/', () {
      final temp = Directory.systemTemp.createTempSync('ai-scaffold-support-');
      try {
        final support = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_ai',
            'test',
            'support',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(support.path, 'handoff_test.dart'),
          "import 'package:test/test.dart';\nvoid main() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAiTestNoDuplicateScaffolding(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('test/support/'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when a confusing test_fixtures.dart is re-added under ai test',
        () {
      final temp = Directory.systemTemp.createTempSync('ai-scaffold-fixtures-');
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
          p.join(planning.path, 'test_fixtures.dart'),
          "import 'package:colonizethis_models/colonizethis_models.dart';\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAiTestNoDuplicateScaffolding(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('test_fixtures.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when an ai test redeclares a TestFixtures class', () {
      final temp = Directory.systemTemp.createTempSync('ai-scaffold-class-');
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
          p.join(planning.path, 'local_fixtures_test.dart'),
          "import 'package:test/test.dart';\n\n"
          'class TestFixtures {\n  static int x() => 1;\n}\n'
          'void main() {}\n',
        );

        final errors = <String>[];
        final exitCode = runCheckAiTestNoDuplicateScaffolding(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('redefines a local'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when ai scaffolding is coherent', () {
      final temp = Directory.systemTemp.createTempSync('ai-scaffold-ok-');
      try {
        final aiTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiTest.path, 'planning', 'ai_planner_fixtures.dart'),
          "import 'package:colonizethis_models/colonizethis_models.dart';\n",
        );
        _writeDartFile(
          p.join(aiTest.path, 'support', 'faithful_handoff.dart'),
          "import 'package:colonizethis_models/colonizethis_models.dart';\n",
        );
        _writeDartFile(
          p.join(aiTest.path, 'support_test', 'faithful_handoff_test.dart'),
          "import 'package:colonizethis_test/game_test_fixtures.dart';\n"
          "import 'package:test/test.dart';\n\n"
          'void main() {\n  TestFixtures.minimalGame();\n}\n',
        );

        final exitCode = runCheckAiTestNoDuplicateScaffolding(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores scaffolding outside the ai package test tree', () {
      final temp = Directory.systemTemp.createTempSync('ai-scaffold-other-');
      try {
        final ordersSupport = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_orders',
            'test',
            'support',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersSupport.path, 'helper_test.dart'),
          "import 'package:test/test.dart';\nvoid main() {}\n",
        );

        final exitCode = runCheckAiTestNoDuplicateScaffolding(
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

  group('aiTestDuplicateScaffoldingViolationReason', () {
    test('flags a _test.dart inside test/support/', () {
      expect(
        aiTestDuplicateScaffoldingViolationReason(
          'packages/colonizethis_ai/test/support/foo_test.dart',
          'foo_test.dart',
          '',
        ),
        isNotNull,
      );
    });

    test('flags the confusing test_fixtures.dart filename', () {
      expect(
        aiTestDuplicateScaffoldingViolationReason(
          'packages/colonizethis_ai/test/planning/test_fixtures.dart',
          'test_fixtures.dart',
          '',
        ),
        isNotNull,
      );
    });

    test('flags abstract final class TestFixtures declarations', () {
      expect(
        aiTestDuplicateScaffoldingViolationReason(
          'packages/colonizethis_ai/test/planning/foo_test.dart',
          'foo_test.dart',
          'abstract final class TestFixtures {}',
        ),
        isNotNull,
      );
    });

    test('does not flag references to the shared TestFixtures symbol', () {
      expect(
        aiTestDuplicateScaffoldingViolationReason(
          'packages/colonizethis_ai/test/planning/foo_test.dart',
          'foo_test.dart',
          "import 'package:colonizethis_test/game_test_fixtures.dart';\n"
          'void main() => TestFixtures.minimalGame();',
        ),
        isNull,
      );
    });

    test('does not flag a non-test scaffolding file in support/', () {
      expect(
        aiTestDuplicateScaffoldingViolationReason(
          'packages/colonizethis_ai/test/support/helpers.dart',
          'helpers.dart',
          "import 'package:colonizethis_models/colonizethis_models.dart';\n",
        ),
        isNull,
      );
    });
  });

  group('aiTestNoDuplicateScaffoldingPathInScope', () {
    test('matches ai package test paths only', () {
      expect(
        aiTestNoDuplicateScaffoldingPathInScope(
          'packages/colonizethis_ai/test/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        aiTestNoDuplicateScaffoldingPathInScope(
          'packages/colonizethis_ai/lib/src/planning/foo.dart',
        ),
        isFalse,
      );
      expect(
        aiTestNoDuplicateScaffoldingPathInScope(
          'packages/colonizethis_orders/test/foo_test.dart',
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
