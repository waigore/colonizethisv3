import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_residual_fat_pin_suite_size.dart';

void main() {
  group('runCheckAiResidualFatPinSuiteSize', () {
    test('fails when observer_goal_phase pin is oversize without cases', () {
      final temp = Directory.systemTemp.createTempSync('ai-residual-fat-');
      try {
        _writePlanningTest(
          temp,
          'observer_goal_phase_test.dart',
          '${List.filled(800, '// pad').join('\n')}\nvoid main() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiResidualFatPinSuiteSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('observer_goal_phase_test.dart'));
        expect(errors.join('\n'), contains('*_cases.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when observer_goal_phase pin imports *_cases.dart', () {
      final temp = Directory.systemTemp.createTempSync('ai-residual-fat-ok-');
      try {
        _writePlanningTest(
          temp,
          'observer_goal_phase_test.dart',
          "import 'observer_goal_phase_phase_and_declare_war_cases.dart';\n"
          '${List.filled(800, '// pad').join('\n')}\n'
          'void main() {}\n',
        );
        final exitCode = runCheckAiResidualFatPinSuiteSize(
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
