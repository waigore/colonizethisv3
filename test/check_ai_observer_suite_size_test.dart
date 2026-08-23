import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_observer_suite_size.dart';

void main() {
  group('runCheckAiObserverSuiteSize', () {
    test('ceiling is 300 after #4602 Slice E', () {
      expect(aiObserverSuitePhysicalLineCeiling, 300);
    });

    test('passes on current repo tree', () {
      expect(runCheckAiObserverSuiteSize('.'), 0);
    });

    test('fails when an observer file exceeds the ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-observer-over-');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeObserverModule(
        temp,
        'fat_observer_test.dart',
        List<String>.filled(
          aiObserverSuitePhysicalLineCeiling + 2,
          '// pad',
        ).join('\n'),
      );
      final errors = <String>[];
      final exitCode = runCheckAiObserverSuiteSize(
        temp.path,
        info: (_) {},
        err: errors.add,
      );
      expect(exitCode, 1);
      expect(errors.join('\n'), contains('fat_observer_test.dart'));
    });

    test('passes when every observer file is under the ceiling', () {
      final temp = Directory.systemTemp.createTempSync('ai-observer-ok-');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeObserverModule(temp, 'slim_observer_test.dart', 'void main() {}\n');
      final exitCode = runCheckAiObserverSuiteSize(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(exitCode, 0);
    });
  });
}

void _writeObserverModule(Directory temp, String basename, String body) {
  final dir = Directory(
    p.join(temp.path, 'packages', 'colonizethis_ai', 'test', 'observer'),
  )..createSync(recursive: true);
  File(p.join(dir.path, basename)).writeAsStringSync(body);
}
