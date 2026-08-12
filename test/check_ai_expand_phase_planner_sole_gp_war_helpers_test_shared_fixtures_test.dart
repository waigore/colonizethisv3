import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_expand_phase_planner_sole_gp_war_helpers_test_shared_fixtures.dart';

void main() {
  group('runCheckAiExpandPhasePlannerSoleGpWarHelpersTestSharedFixtures', () {
    test('fails when contract redeclares _gameWithGpsAndMinors', () {
      final temp = Directory.systemTemp.createTempSync('ai-sole-gp-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'expand_phase_planner_sole_gp_war_helpers_test.dart',
          'Game _gameWithGpsAndMinors() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code =
            runCheckAiExpandPhasePlannerSoleGpWarHelpersTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWithGpsAndMinors'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when cases redeclare _gameWithProvinces', () {
      final temp = Directory.systemTemp.createTempSync('ai-sole-prov-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'expand_phase_planner_sole_gp_war_helpers_pivot_cases.dart',
          'Game _gameWithProvinces() {\n'
          '  throw UnimplementedError();\n'
          '}\n',
        );
        final errors = <String>[];
        final code =
            runCheckAiExpandPhasePlannerSoleGpWarHelpersTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_gameWithProvinces'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when adopters use shared factories', () {
      final temp = Directory.systemTemp.createTempSync('ai-sole-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'expand_phase_planner_sole_gp_war_helpers_test.dart',
          "import '../support/"
          "expand_phase_planner_sole_gp_war_helpers_test_support.dart';\n",
        );
        final code =
            runCheckAiExpandPhasePlannerSoleGpWarHelpersTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-sole-miss-');
      try {
        final code =
            runCheckAiExpandPhasePlannerSoleGpWarHelpersTestSharedFixtures(
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
    p.join(
      support.path,
      'expand_phase_planner_sole_gp_war_helpers_test_support.dart',
    ),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
