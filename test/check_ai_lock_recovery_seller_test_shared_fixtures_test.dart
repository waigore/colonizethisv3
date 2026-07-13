import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_lock_recovery_seller_test_shared_fixtures.dart';

void main() {
  group('runCheckAiLockRecoverySellerTestSharedFixtures', () {
    test('fails when cast-iron pin redeclares _lockRecoverySellerGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-lock-cast-');
      try {
        _writeSupportStub(temp);
        _writeCastIronTest(
          temp,
          "import 'package:test/test.dart';\n\n"
          'Game _lockRecoverySellerGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n\n'
          'void main() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiLockRecoverySellerTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('_lockRecoverySellerGame'));
        expect(
          errors.join('\n'),
          contains('buildCastIronLabourLockRecoverySellerGame'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters import shared builders', () {
      final temp = Directory.systemTemp.createTempSync('ai-lock-ok-');
      try {
        _writeSupportStub(temp);
        _writeCastIronTest(
          temp,
          "import 'package:test/test.dart';\n"
          "import '../support/lock_recovery_seller_test_support.dart';\n\n"
          'void main() {\n'
          '  final game = buildCastIronLabourLockRecoverySellerGame(\n'
          '    workerPool: Object(),\n'
          '    stockpile: Object(),\n'
          '  );\n'
          '  expect(game, isNotNull);\n'
          '}\n',
        );
        _writeH8Test(
          temp,
          "import 'package:test/test.dart';\n"
          "import '../support/lock_recovery_seller_test_support.dart';\n\n"
          'void main() {\n'
          '  final game = buildH8FeedstockLockRecoverySellerGame(treasury: 0);\n'
          '  expect(game, isNotNull);\n'
          '}\n',
        );
        final exitCode = runCheckAiLockRecoverySellerTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when the shared support file is missing', () {
      final temp = Directory.systemTemp.createTempSync('ai-lock-missing-');
      try {
        final exitCode = runCheckAiLockRecoverySellerTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeSupportStub(Directory temp) {
  final support = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'support'),
  )..createSync(recursive: true);
  File(
    p.join(support.path, 'lock_recovery_seller_test_support.dart'),
  ).writeAsStringSync(
    'Object buildCastIronLabourLockRecoverySellerGame({\n'
    '  required Object workerPool,\n'
    '  required Object stockpile,\n'
    '}) => Object();\n'
    'Object buildH8FeedstockLockRecoverySellerGame({required int treasury}) =>\n'
    '    Object();\n',
  );
}

void _writeCastIronTest(Directory temp, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'cast_iron_labour_gate_test.dart'),
  ).writeAsStringSync(body);
}

void _writeH8Test(Directory temp, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(
      planning.path,
      'domain_planner_orchestrator_h8_feedstock_civilian_work_test.dart',
    ),
  ).writeAsStringSync(body);
}
