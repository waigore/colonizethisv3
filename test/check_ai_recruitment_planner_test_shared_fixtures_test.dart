import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_recruitment_planner_test_shared_fixtures.dart';

void main() {
  group('runCheckAiRecruitmentPlannerTestSharedFixtures', () {
    test('fails when a pin redeclares _gameWith', () {
      final temp = Directory.systemTemp.createTempSync('ai-recruit-bad-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'recruitment_planner_test.dart',
          'Game _gameWith(Object player) => throw UnimplementedError();\n',
        );
        final errors = <String>[];
        final code = runCheckAiRecruitmentPlannerTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWith'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when pins import shared support', () {
      final temp = Directory.systemTemp.createTempSync('ai-recruit-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'recruitment_planner_test.dart',
          "import 'recruitment_planner_test_support.dart';\n",
        );
        _writeAdopter(
          temp,
          'recruitment_planner_paper_ledger_test.dart',
          "import 'recruitment_planner_test_support.dart';\n",
        );
        final code = runCheckAiRecruitmentPlannerTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(code, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when shared support is missing', () {
      final temp = Directory.systemTemp.createTempSync('ai-recruit-miss-');
      try {
        final code = runCheckAiRecruitmentPlannerTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(code, 1);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeSupport(Directory temp) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'recruitment_planner_test_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
