import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_colonial_military_naval_pin_suite_size.dart';

void main() {
  group('runCheckAiColonialMilitaryNavalPinSuiteSize', () {
    test('fails when military pin is oversize without cases import', () {
      final temp = Directory.systemTemp.createTempSync('ai-mil-size-');
      try {
        _writePlanningTest(
          temp,
          'colonial_phase_planner_military_test.dart',
          '${List.filled(800, '// pad').join('\n')}\nvoid main() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiColonialMilitaryNavalPinSuiteSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('*_cases.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when military pin imports *_cases.dart', () {
      final temp = Directory.systemTemp.createTempSync('ai-mil-size-ok-');
      try {
        _writePlanningTest(
          temp,
          'colonial_phase_planner_military_test.dart',
          "import 'colonial_phase_planner_military_cases.dart';\n"
          '${List.filled(800, '// pad').join('\n')}\n'
          'void main() {}\n',
        );
        final exitCode = runCheckAiColonialMilitaryNavalPinSuiteSize(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when lite-naval pin is oversize without cases import', () {
      final temp = Directory.systemTemp.createTempSync('ai-lite-naval-size-');
      try {
        _writePlanningTest(
          temp,
          'colonial_phase_planner_colonial_lite_naval_test.dart',
          '${List.filled(800, '// pad').join('\n')}\nvoid main() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiColonialMilitaryNavalPinSuiteSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(
          errors.join('\n'),
          contains('colonial_phase_planner_colonial_lite_naval_test.dart'),
        );
        expect(errors.join('\n'), contains('*_cases.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when lite-naval pin imports *_cases.dart', () {
      final temp = Directory.systemTemp.createTempSync('ai-lite-naval-ok-');
      try {
        _writePlanningTest(
          temp,
          'colonial_phase_planner_colonial_lite_naval_test.dart',
          "import 'colonial_phase_planner_colonial_lite_naval_cases.dart';\n"
          '${List.filled(800, '// pad').join('\n')}\n'
          'void main() {}\n',
        );
        final exitCode = runCheckAiColonialMilitaryNavalPinSuiteSize(
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
}

void _writePlanningTest(Directory temp, String basename, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, basename)).writeAsStringSync(body);
}
