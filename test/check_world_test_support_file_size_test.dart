import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_test_support_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckWorldTestSupportFileSize', () {
    test('passes on current repo tree under #4611 ceiling', () {
      expect(worldTestSupportFileSizeCeiling, 250);
      expect(runCheckWorldTestSupportFileSize('.'), 0);
    });

    test('fails when a support file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync(
        'world_support_size_bad',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_world/test/world_test_support/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckWorldTestSupportFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('passes when support files stay under the ceiling', () {
      final root = Directory.systemTemp.createTempSync('world_support_size_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_world/test/world_test_support/ok.dart',
        '// small\n',
      );

      expect(runCheckWorldTestSupportFileSize(root.path, ceiling: 10), 0);
    });
  });
}
