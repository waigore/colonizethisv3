import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_residual_fat_pin_suite_size.dart';

void main() {
  group('runCheckAiResidualFatPinSuiteSize', () {
    test('ceiling is 400 after #4365 Slice B', () {
      expect(residualFatPinSuitePhysicalLineCeiling, 400);
    });

    test('fails when gated residual fat pin is oversize without cases', () {
      final temp = Directory.systemTemp.createTempSync('ai-residual-fat-');
      try {
        _writePlanningTest(
          temp,
          'treasury_planner_treasury_budget_test.dart',
          '${List.filled(800, '// pad').join('\n')}\nvoid main() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiResidualFatPinSuiteSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(
          errors.join('\n'),
          contains('treasury_planner_treasury_budget_test.dart'),
        );
        expect(errors.join('\n'), contains('*_cases.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when gated residual fat pin imports *_cases.dart', () {
      final temp = Directory.systemTemp.createTempSync('ai-residual-fat-ok-');
      try {
        _writePlanningTest(
          temp,
          'treasury_planner_treasury_budget_test.dart',
          "import 'treasury_planner_treasury_budget_deficit_clamp_cases.dart';\n"
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
