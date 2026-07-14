import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_expand_peace_pin_suite_size.dart';

void main() {
  group('runCheckAiExpandPeacePinSuiteSize', () {
    test('fails when an oversize peace pin has no *_cases.dart import', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-size-');
      try {
        _writePeaceTest(
          temp,
          'fat_peace_test.dart',
          '${List.filled(700, '// pad').join('\n')}\nvoid main() {}\n',
        );
        final errors = <String>[];
        final exitCode = runCheckAiExpandPeacePinSuiteSize(
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

    test('passes when an oversize peace pin imports *_cases.dart', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-size-ok-');
      try {
        _writePeaceTest(
          temp,
          'fat_peace_test.dart',
          "import 'fat_peace_cases.dart';\n"
              '${List.filled(700, '// pad').join('\n')}\n'
              'void main() {}\n',
        );
        final exitCode = runCheckAiExpandPeacePinSuiteSize(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when a peace pin is under the physical-line ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-peace-size-thin-');
      try {
        _writePeaceTest(
          temp,
          'thin_peace_test.dart',
          "import 'thin_peace_cases.dart';\n\nvoid main() {}\n",
        );
        final exitCode = runCheckAiExpandPeacePinSuiteSize(
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

void _writePeaceTest(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(
    p.join(planning.path, 'expand_phase_planner_$name'),
  ).writeAsStringSync(body);
}
