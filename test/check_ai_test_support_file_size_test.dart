import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_test_support_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckAiTestSupportFileSize', () {
    test('passes on current repo tree under 400 physical-line ceiling', () {
      expect(runCheckAiTestSupportFileSize('.'), 0);
    });

    test('grandfather allowlist is empty after #4291 split', () {
      expect(aiTestSupportFileSizeGrandfatheredForTests, isEmpty);
    });

    test('fails when a support file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('ai_support_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_ai/test/support/fat_support.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckAiTestSupportFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat_support.dart'));
    });

    test('skips s7d support modules (separate gate)', () {
      final root = Directory.systemTemp.createTempSync('ai_support_s7d_skip');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_ai/test/support/s7d/fat_s7d.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final code = runCheckAiTestSupportFileSize(
        root.path,
        ceiling: 10,
      );
      expect(code, 0);
    });

    test('skips an over-cap file listed in the grandfather allowlist', () {
      final root = Directory.systemTemp.createTempSync('ai_support_size_gf');
      addTearDown(() => root.deleteSync(recursive: true));
      const grandfatheredRel =
          'packages/colonizethis_ai/test/support/legacy_support.dart';
      _writeFile(
        root,
        grandfatheredRel,
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final code = runCheckAiTestSupportFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [grandfatheredRel],
      );
      expect(code, 0);
    });

    test('fails when a grandfather entry no longer exists', () {
      final root = Directory.systemTemp.createTempSync('ai_support_size_stale');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(
        p.join(root.path, 'packages/colonizethis_ai/test/support'),
      ).createSync(recursive: true);

      final errors = <String>[];
      final code = runCheckAiTestSupportFileSize(
        root.path,
        grandfatheredPaths: const [
          'packages/colonizethis_ai/test/support/missing_support.dart',
        ],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('stale grandfather'));
    });
  });
}
