// Refs #3393, Phase 5 — guards `repo.models_file_size`: colonizethis_models
// lib/src files must stay at or below 500 non-comment lines, with files pending
// a split grandfathered via tool/models_file_size_baseline.json.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_models_file_size.dart';

void main() {
  group('repo.models_file_size', () {
    test('passes on real repo workspace (within baseline)', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckModelsFileSize(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('check_models_file_size: no violations outside baseline.'),
      );
    });

    test('threshold is 500 non-comment lines', () {
      expect(maxModelsNonCommentLinesForTests(), 500);
    });

    test('fails when a non-baselined file exceeds the limit', () {
      final temp = Directory.systemTemp.createTempSync(
        'models_file_size_fail_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeModelsSource(temp.path, 'oversized.dart', _codeLines(501));
      _writeBaseline(temp.path, const <String>[]);

      final errLogs = <String>[];
      final code = runCheckModelsFileSize(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('packages/colonizethis_models/lib/src/oversized.dart'),
      );
    });

    test('passes when an oversized file is grandfathered in the baseline', () {
      final temp = Directory.systemTemp.createTempSync(
        'models_file_size_base_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeModelsSource(temp.path, 'legacy.dart', _codeLines(501));
      _writeBaseline(temp.path, const <String>[
        'packages/colonizethis_models/lib/src/legacy.dart',
      ]);

      final code = runCheckModelsFileSize(temp.path, info: (_) {}, err: (_) {});
      expect(code, 0);
    });

    test('does not count comment-only lines toward the limit', () {
      final temp = Directory.systemTemp.createTempSync('models_file_size_cmt_');
      addTearDown(() => temp.deleteSync(recursive: true));

      // 600 comment lines + 10 code lines = 10 non-comment lines, well under.
      final buffer = StringBuffer();
      for (var i = 0; i < 600; i++) {
        buffer.writeln('// comment line $i');
      }
      buffer.write(_codeLines(10));
      _writeModelsSource(temp.path, 'mostly_comments.dart', buffer.toString());
      _writeBaseline(temp.path, const <String>[]);

      final code = runCheckModelsFileSize(temp.path, info: (_) {}, err: (_) {});
      expect(code, 0);
    });

    test('fails when the models src directory is missing', () {
      final temp = Directory.systemTemp.createTempSync(
        'models_file_size_miss_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final errLogs = <String>[];
      final code = runCheckModelsFileSize(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('missing'));
    });
  });
}

String _codeLines(int count) {
  final buffer = StringBuffer();
  for (var i = 0; i < count; i++) {
    buffer.writeln('const int v$i = $i;');
  }
  return buffer.toString();
}

void _writeModelsSource(String repoRoot, String fileName, String content) {
  final dir = Directory(
    p.join(repoRoot, 'packages', 'colonizethis_models', 'lib', 'src'),
  )..createSync(recursive: true);
  File(p.join(dir.path, fileName)).writeAsStringSync(content);
}

void _writeBaseline(String repoRoot, List<String> entries) {
  final dir = Directory(p.join(repoRoot, 'tool'))..createSync(recursive: true);
  File(
    p.join(dir.path, 'models_file_size_baseline.json'),
  ).writeAsStringSync(jsonEncode(entries));
}
