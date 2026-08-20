import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_colonizethis_test_lib_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckColonizethisTestLibFileSize', () {
    test('colonizethisTestLibFileSizeCeiling is pinned at phase-1 target', () {
      expect(colonizethisTestLibFileSizeCeiling, 250);
    });

    test('passes on current repo tree under 250 physical-line ceiling', () {
      expect(runCheckColonizethisTestLibFileSize('.'), 0);
    });

    test('grandfather allowlist is empty', () {
      expect(colonizethisTestLibFileSizeGrandfatheredForTests, isEmpty);
    });

    test('fails when a colonizethis_test lib file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('ct_test_lib_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_test/lib/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckColonizethisTestLibFileSize(
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
