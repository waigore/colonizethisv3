import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_test_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyTestFileSize', () {
    test('passes on current repo tree under phase-9 ceiling', () {
      expect(runCheckEconomyTestFileSize('.'), 0);
    });

    test('pins economyTestFileSizeCeiling at 300', () {
      expect(economyTestFileSizeCeiling, 300);
    });

    test('fails when an economy test file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('economy_test_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy/test/fat_test.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckEconomyTestFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat_test.dart'));
    });
  });
}
