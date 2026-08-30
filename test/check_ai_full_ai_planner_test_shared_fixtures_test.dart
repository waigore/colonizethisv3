import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_full_ai_planner_test_shared_fixtures.dart';

void main() {
  group('runCheckAiFullAiPlannerTestSharedFixtures', () {
    test('fails when contract redeclares _minimalGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-full-min-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'full_ai_planner_test.dart',
          'Game _minimalGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiFullAiPlannerTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_minimalGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when determinism pin redeclares _scenarioGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-full-scen-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'full_ai_planner_determinism_test.dart',
          'Game _scenarioGame() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiFullAiPlannerTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_scenarioGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-full-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'full_ai_planner_test.dart',
          "import '../support/full_ai_planner_test_support.dart';\n",
        );
        final code = runCheckAiFullAiPlannerTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-full-miss-');
      try {
        final code = runCheckAiFullAiPlannerTestSharedFixtures(
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
  final support = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'support'),
  )..createSync(recursive: true);
  File(
    p.join(support.path, 'full_ai_planner_test_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
