import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_turn_test_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckTurnTestFileSize', () {
    test(
      'passes on current repo tree under wave-8 300 physical-line ceiling',
      () {
        expect(runCheckTurnTestFileSize('.'), 0);
      },
    );

    test('ceiling is 300 after #4583 Slice C ratchet', () {
      expect(turnTestFileSizeCeiling, 300);
    });

    test('ignores test/support paths governed by support LOC gate', () {
      final root = Directory.systemTemp.createTempSync(
        'turn_test_size_support',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_turn/test/support/fat.dart',
        List.generate(12, (i) => '// support $i').join('\n'),
      );
      _writeFile(root, 'packages/colonizethis_turn/test/ok.dart', '// small\n');

      expect(runCheckTurnTestFileSize(root.path, ceiling: 10), 0);
    });

    test('fails when a non-support test file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('turn_test_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_turn/test/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckTurnTestFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });
  });
}
