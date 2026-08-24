import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_file_size.dart';

void main() {
  test('wave-22 app/test ceiling is 350', () {
    expect(maxAppTestPhysicalLinesForTests(), 350);
    expect(appTestFileSizeAllowlistForTests, isEmpty);
  });

  test('passes for the real app/test tree with shrink-only allowlist', () {
    final logs = <String>[];
    final code = runCheckAppTestFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every app/test file must stay at or below '
          '${maxAppTestPhysicalLinesForTests()} physical lines '
          '(allowlisted baseline excepted).\n${logs.join('\n')}',
    );
  });

  test('allowlisted offenders still exceed the cap (shrink-only)', () {
    // Allowlist may be empty once the shrink-only baseline is cleared.
    for (final relativePath in appTestFileSizeAllowlistForTests) {
      final file = File('${Directory.current.path}/$relativePath');
      expect(file.existsSync(), isTrue, reason: relativePath);
      final lines = file.readAsLinesSync().length;
      expect(
        lines,
        greaterThan(maxAppTestPhysicalLinesForTests()),
        reason:
            '$relativePath must remain over the cap while allowlisted '
            '(got $lines).',
      );
    }
  });

  test('fails when a non-allowlisted file exceeds the cap', () {
    final temp = Directory.systemTemp.createTempSync('check_app_test_size_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/app/test').createSync(recursive: true);
    File('${temp.path}/app/test/huge_test.dart')
      ..createSync()
      ..writeAsStringSync(List.filled(381, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckAppTestFileSize(
      temp.path,
      allowlistPaths: const <String>[],
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('huge_test.dart'));
  });

  test('fails on stale allowlist entry that is now under the cap', () {
    final temp = Directory.systemTemp.createTempSync('check_app_test_stale_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/app/test').createSync(recursive: true);
    const relative = 'app/test/shrunk_test.dart';
    File('${temp.path}/$relative')
      ..createSync()
      ..writeAsStringSync('void main() {}\n');

    final logs = <String>[];
    final code = runCheckAppTestFileSize(
      temp.path,
      allowlistPaths: const [relative],
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('stale allowlist'));
  });
}
