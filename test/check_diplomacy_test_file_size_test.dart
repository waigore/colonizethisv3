import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_diplomacy_test_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckDiplomacyTestFileSize', () {
    test('passes on current repo tree under 250 physical lines', () {
      expect(runCheckDiplomacyTestFileSize('.'), 0);
    });

    test('fails when a diplomacy test file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('diplomacy_test_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_diplomacy/test/diplomacy/fat_test.dart',
        List.generate(251, (i) => '// line $i').join('\n'),
      );
      final errors = <String>[];
      final code = runCheckDiplomacyTestFileSize(
        root.path,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat_test.dart'));
    });
  });
}
