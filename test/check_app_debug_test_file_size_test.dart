import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_debug_test_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckAppDebugTestFileSize', () {
    test('passes on current repo tree under 400 physical-line ceiling', () {
      expect(runCheckAppDebugTestFileSize('.'), 0);
    });

    test('grandfather allowlist is empty after #4484 densify', () {
      expect(appDebugTestFileSizeGrandfatheredForTests, isEmpty);
    });

    test('pins the 400 ceiling', () {
      expect(maxAppDebugTestFilePhysicalLinesForTests(), 400);
    });

    test('fails when a debug-console test file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('app_dbg_test_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_app_debug/test/fat_test.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckAppDebugTestFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat_test.dart'));
    });

    test('skips an over-cap file listed in the grandfather allowlist', () {
      final root = Directory.systemTemp.createTempSync('app_dbg_test_size_gf');
      addTearDown(() => root.deleteSync(recursive: true));
      const grandfatheredRel =
          'packages/colonizethis_app_debug/test/legacy_test.dart';
      _writeFile(
        root,
        grandfatheredRel,
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final code = runCheckAppDebugTestFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [grandfatheredRel],
      );
      expect(code, 0);
    });

    test('fails when a grandfather entry no longer exists', () {
      final root = Directory.systemTemp.createTempSync('app_dbg_test_size_stale');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(
        p.join(root.path, 'packages/colonizethis_app_debug/test'),
      ).createSync(recursive: true);

      final errors = <String>[];
      final code = runCheckAppDebugTestFileSize(
        root.path,
        grandfatheredPaths: const [
          'packages/colonizethis_app_debug/test/missing_test.dart',
        ],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('stale grandfather'));
    });
  });
}
