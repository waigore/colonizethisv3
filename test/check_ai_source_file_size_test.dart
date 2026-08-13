import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_source_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckAiSourceFileSize', () {
    test('passes on current repo tree under 300 physical-line ceiling', () {
      expect(runCheckAiSourceFileSize('.'), 0);
    });

    test('ceiling is 300 after #4365 Slice A headroom ratchet', () {
      expect(aiSourceFileSizeCeiling, 300);
    });

    test('grandfather allowlist is empty after #4079 / #4104 / #4310 / #4365 splits', () {
      expect(aiSourceFileSizeGrandfatheredForTests, isEmpty);
    });

    test('fails when an AI lib/src file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_ai/lib/src/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckAiSourceFileSize(
        root.path,
        ceiling: 10,
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('skips an over-cap file listed in the grandfather allowlist', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_gf');
      addTearDown(() => root.deleteSync(recursive: true));
      const grandfatheredRel = 'packages/colonizethis_ai/lib/src/legacy.dart';
      _writeFile(
        root,
        grandfatheredRel,
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final code = runCheckAiSourceFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [grandfatheredRel],
      );
      expect(code, 0);
    });

    test('fails when a grandfather entry no longer exists', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_stale');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(
        p.join(root.path, 'packages/colonizethis_ai/lib/src'),
      ).createSync(recursive: true);

      final errors = <String>[];
      final code = runCheckAiSourceFileSize(
        root.path,
        grandfatheredPaths: const [
          'packages/colonizethis_ai/lib/src/missing.dart',
        ],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('stale grandfather'));
    });

    test('fails when a grandfather entry is now under the ceiling', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_undercap');
      addTearDown(() => root.deleteSync(recursive: true));
      const grandfatheredRel = 'packages/colonizethis_ai/lib/src/slim.dart';
      _writeFile(
        root,
        grandfatheredRel,
        List.generate(5, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckAiSourceFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [grandfatheredRel],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('now under'));
    });

    test('ignores generated files over the ceiling', () {
      final root = Directory.systemTemp.createTempSync('ai_src_size_gen');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_ai/lib/src/huge.g.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final code = runCheckAiSourceFileSize(root.path, ceiling: 10);
      expect(code, 0);
    });
  });
}
