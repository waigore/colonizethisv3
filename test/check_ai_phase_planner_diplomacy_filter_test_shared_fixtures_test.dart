import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_phase_planner_diplomacy_filter_test_shared_fixtures.dart';

void main() {
  group('runCheckAiPhasePlannerDiplomacyFilterTestSharedFixtures', () {
    test('fails when a pin redeclares _buildGame', () {
      final temp = Directory.systemTemp.createTempSync('ai-diplo-bad-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'phase_planner_diplomacy_ow_bonus_scaling_test.dart',
          'Game _buildGame() => throw UnimplementedError();\n',
        );
        final errors = <String>[];
        final code = runCheckAiPhasePlannerDiplomacyFilterTestSharedFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('_buildGame'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when pins import shared support', () {
      final temp = Directory.systemTemp.createTempSync('ai-diplo-ok-');
      try {
        _writeSupport(temp);
        _writeAdopter(
          temp,
          'phase_planner_diplomacy_ow_bonus_scaling_test.dart',
          "import '../support/phase_planner_diplomacy_filter_test_support.dart';\n",
        );
        _writeAdopter(
          temp,
          'phase_planner_diplomacy_declare_war_nw_suppression_test.dart',
          "import '../support/phase_planner_diplomacy_filter_test_support.dart';\n",
        );
        final code = runCheckAiPhasePlannerDiplomacyFilterTestSharedFixtures(
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
      final temp = Directory.systemTemp.createTempSync('ai-diplo-miss-');
      try {
        final code = runCheckAiPhasePlannerDiplomacyFilterTestSharedFixtures(
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
    p.join(support.path, 'phase_planner_diplomacy_filter_test_support.dart'),
  ).writeAsStringSync('// stub\n');
}

void _writeAdopter(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
