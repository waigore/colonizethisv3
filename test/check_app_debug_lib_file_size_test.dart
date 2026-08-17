import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_debug_lib_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckAppDebugLibFileSize', () {
    test('passes on current repo tree under 200 physical-line ceiling', () {
      expect(runCheckAppDebugLibFileSize('.'), 0);
    });

    test('grandfather allowlist is empty after #4484', () {
      expect(appDebugLibFileSizeGrandfatheredForTests, isEmpty);
    });

    test('pins the 200 ceiling', () {
      expect(maxAppDebugLibFilePhysicalLinesForTests(), 200);
    });

    test('fails when a debug-console lib file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('app_dbg_lib_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_app_debug/lib/src/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckAppDebugLibFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('skips an over-cap file listed in the grandfather allowlist', () {
      final root = Directory.systemTemp.createTempSync('app_dbg_lib_size_gf');
      addTearDown(() => root.deleteSync(recursive: true));
      const grandfatheredRel =
          'packages/colonizethis_app_debug/lib/src/legacy.dart';
      _writeFile(
        root,
        grandfatheredRel,
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final code = runCheckAppDebugLibFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [grandfatheredRel],
      );
      expect(code, 0);
    });

    test('fails when a grandfather entry no longer exists', () {
      final root = Directory.systemTemp.createTempSync('app_dbg_lib_size_stale');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(
        p.join(root.path, 'packages/colonizethis_app_debug/lib/src'),
      ).createSync(recursive: true);

      final errors = <String>[];
      final code = runCheckAppDebugLibFileSize(
        root.path,
        grandfatheredPaths: const [
          'packages/colonizethis_app_debug/lib/src/missing.dart',
        ],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('stale grandfather'));
    });
  });
}
