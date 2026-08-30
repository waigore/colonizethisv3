import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_test_file_size.dart';

void main() {
  group('runCheckAiTestFileSize', () {
    test('ceiling is 250 after #4669 Slice E', () {
      expect(aiTestFileSizeCeiling, 250);
    });

    test('passes on the current repo tree', () {
      expect(runCheckAiTestFileSize('.'), 0);
    });

    test('fails when a planning file exceeds the ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-test-size-over-');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writePlanning(
        temp,
        'fat_host_test.dart',
        List<String>.filled(aiTestFileSizeCeiling + 2, '// pad').join('\n'),
      );
      final errors = <String>[];
      final exitCode = runCheckAiTestFileSize(
        temp.path,
        info: (_) {},
        err: errors.add,
      );
      expect(exitCode, 1);
      expect(errors.join('\n'), contains('fat_host_test.dart'));
    });

    test('passes when planning files stay under the ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-test-size-ok-');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writePlanning(temp, 'thin_host_test.dart', 'void main() {}\n');
      expect(runCheckAiTestFileSize(temp.path, info: (_) {}, err: (_) {}), 0);
    });

    test('scopes perception test files under the ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-test-size-perc-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final perception = Directory(
        p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'perception'),
      )..createSync(recursive: true);
      File(p.join(perception.path, 'fat_perception_test.dart')).writeAsStringSync(
        List<String>.filled(aiTestFileSizeCeiling + 2, '// pad').join('\n'),
      );
      final errors = <String>[];
      final exitCode = runCheckAiTestFileSize(
        temp.path,
        info: (_) {},
        err: errors.add,
      );
      expect(exitCode, 1);
      expect(errors.join('\n'), contains('fat_perception_test.dart'));
    });

    test('ignores observer files (separate suite gate)', () {
      final temp = Directory.systemTemp.createTempSync('ai-test-size-skip-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final observer = Directory(
        p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'observer'),
      )..createSync(recursive: true);
      File(p.join(observer.path, 'fat_observer_test.dart')).writeAsStringSync(
        List<String>.filled(aiTestFileSizeCeiling + 20, '// pad').join('\n'),
      );
      expect(runCheckAiTestFileSize(temp.path, info: (_) {}, err: (_) {}), 0);
    });
  });
}

void _writePlanning(Directory temp, String name, String body) {
  final planning = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'planning'),
  )..createSync(recursive: true);
  File(p.join(planning.path, name)).writeAsStringSync(body);
}
