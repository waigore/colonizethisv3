import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_planning_cases_suite_size.dart';

void main() {
  group('runCheckAiPlanningCasesSuiteSize', () {
    test('ceiling is 400 after #4365 Slice B', () {
      expect(aiPlanningCasesSuitePhysicalLineCeiling, 400);
    });

    test('fails when an in-scope *_cases.dart exceeds the ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-cases-size-');
      try {
        _writeCases(
          temp,
          'fat_cases.dart',
          '${List.filled(700, '// pad').join('\n')}\nvoid registerFat() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiPlanningCasesSuiteSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('physical lines'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when an in-scope *_cases.dart is under the ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-cases-size-ok-');
      try {
        _writeCases(temp, 'thin_cases.dart', 'void registerThin() {}\n');
        final exitCode = runCheckAiPlanningCasesSuiteSize(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores non-cases planning Dart files', () {
      final temp = Directory.systemTemp.createTempSync('ai-cases-size-skip-');
      try {
        final planning = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
        )..createSync(recursive: true);
        File(p.join(planning.path, 'fat_test.dart')).writeAsStringSync(
          '${List.filled(700, '// pad').join('\n')}\nvoid main() {}\n',
        );
        final exitCode = runCheckAiPlanningCasesSuiteSize(
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

void _writeCases(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
