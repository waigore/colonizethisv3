import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_colonizethis_setup_test_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckColonizethisSetupTestFileSize', () {
    test('passes on current repo tree under wave-8 ceiling', () {
      expect(setupTestFileSizeCeiling, 250);
      expect(runCheckColonizethisSetupTestFileSize('.'), 0);
    });

    test('ignores setup/support paths', () {
      final root = Directory.systemTemp.createTempSync(
        'setup_test_size_support',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_setup/test/setup/support/fat.dart',
        List.generate(12, (i) => '// support $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_setup/test/setup/ok.dart',
        '// small\n',
      );

      expect(
        runCheckColonizethisSetupTestFileSize(
          root.path,
          ceiling: 10,
          grandfatheredPaths: const [],
        ),
        0,
      );
    });

    test('fails when a non-support test file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('setup_test_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_setup/test/setup/fat.dart',
        List.generate(251, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckColonizethisSetupTestFileSize(
        root.path,
        ceiling: 250,
        grandfatheredPaths: const [],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });
  });
}
