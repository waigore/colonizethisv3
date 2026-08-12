import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_test_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckWorldTestFileSize', () {
    test('passes on current repo tree under wave-6 ceiling', () {
      expect(worldTestFileSizeCeiling, 320);
      expect(runCheckWorldTestFileSize('.'), 0);
    });

    test('ignores world_test_support paths', () {
      final root = Directory.systemTemp.createTempSync('world_test_size_support');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_world/test/world_test_support/fat.dart',
        List.generate(12, (i) => '// support $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_world/test/world/ok.dart',
        '// small\n',
      );

      expect(
        runCheckWorldTestFileSize(
          root.path,
          ceiling: 10,
          grandfatheredPaths: const [],
        ),
        0,
      );
    });

    test('fails when a non-support test file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('world_test_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_world/test/world/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckWorldTestFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('ignores grandfathered near-cap suites', () {
      final root = Directory.systemTemp.createTempSync('world_test_size_grand');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_world/test/world/player_view_build_test.dart',
        List.generate(12, (i) => '// grandfathered $i').join('\n'),
      );

      expect(
        runCheckWorldTestFileSize(
          root.path,
          ceiling: 10,
          grandfatheredPaths: const [
            'packages/colonizethis_world/test/world/player_view_build_test.dart',
          ],
        ),
        0,
      );
    });
  });
}
