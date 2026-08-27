import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_save_source_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckSaveSourceFileSize', () {
    test('ceiling is 250 after #4664', () {
      expect(saveSourceFileSizeCeiling, 250);
    });

    test('passes on current repo tree under 250 physical-line ceiling', () {
      expect(runCheckSaveSourceFileSize('.'), 0);
    });

    test('grandfather allowlist is empty after #4077 splits', () {
      expect(saveSourceFileSizeGrandfatheredForTests, isEmpty);
    });

    test('fails when a save lib/src file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('save_src_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_save/lib/src/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckSaveSourceFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('skips an over-cap file listed in the grandfather allowlist', () {
      final root = Directory.systemTemp.createTempSync('save_src_size_gf');
      addTearDown(() => root.deleteSync(recursive: true));
      const grandfatheredRel = 'packages/colonizethis_save/lib/src/legacy.dart';
      _writeFile(
        root,
        grandfatheredRel,
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final code = runCheckSaveSourceFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [grandfatheredRel],
      );
      expect(code, 0);
    });

    test('fails when a grandfather entry no longer exists', () {
      final root = Directory.systemTemp.createTempSync('save_src_size_stale');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(
        p.join(root.path, 'packages/colonizethis_save/lib/src'),
      ).createSync(recursive: true);

      final errors = <String>[];
      final code = runCheckSaveSourceFileSize(
        root.path,
        grandfatheredPaths: const [
          'packages/colonizethis_save/lib/src/missing.dart',
        ],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('stale grandfather'));
    });
  });
}
