import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_planning_ow_tech_helpers_test_shared_fixtures.dart';

void main() {
  group('runCheckAiPlanningOwTechHelpersTestSharedFixtures', () {
    test('fails when contract redeclares _gameOwning', () {
      final temp = Directory.systemTemp.createTempSync('ai-ow-own-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'planning_ow_tech_helpers_test.dart',
          'Game _gameOwning(Map<String, int> c) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPlanningOwTechHelpersTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameOwning'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when contract redeclares _gameWithTechs', () {
      final temp = Directory.systemTemp.createTempSync('ai-ow-tech-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'planning_ow_tech_helpers_test.dart',
          'Game _gameWithTechs(Map<String, int> c) {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPlanningOwTechHelpersTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWithTechs'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when contract redeclares _gameWithExhaustedGp', () {
      final temp = Directory.systemTemp.createTempSync('ai-ow-exh-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'planning_ow_tech_helpers_test.dart',
          'Game _gameWithExhaustedGp() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code = runCheckAiPlanningOwTechHelpersTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWithExhaustedGp'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-ow-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'planning_ow_tech_helpers_test.dart',
          "import '../support/planning_ow_tech_helpers_test_support.dart';\n",
        );
        final code = runCheckAiPlanningOwTechHelpersTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-ow-miss-');
      try {
        final code = runCheckAiPlanningOwTechHelpersTestSharedFixtures(
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
    p.join(support.path, 'planning_ow_tech_helpers_test_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
