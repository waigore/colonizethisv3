import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_support_file_size.dart';

void main() {
  test('passes for the real app/test/support tree with shrink-only allowlist', () {
    final logs = <String>[];
    final code = runCheckAppTestSupportFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every app/test/support file must stay at or below '
          '${maxAppTestSupportPhysicalLinesForTests()} physical lines '
          '(allowlisted baseline excepted).\n${logs.join('\n')}',
    );
  });

  test('allowlisted offenders still exceed the cap (shrink-only)', () {
    for (final relativePath in appTestSupportFileSizeAllowlistForTests) {
      final file = File('${Directory.current.path}/$relativePath');
      expect(file.existsSync(), isTrue, reason: relativePath);
      final lines = file.readAsLinesSync().length;
      expect(
        lines,
        greaterThan(maxAppTestSupportPhysicalLinesForTests()),
        reason:
            '$relativePath must remain over the cap while allowlisted '
            '(got $lines).',
      );
    }
  });

  test('fails when a non-allowlisted support file exceeds the cap', () {
    final temp =
        Directory.systemTemp.createTempSync('check_app_support_size_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/app/test/support').createSync(recursive: true);
    File('${temp.path}/app/test/support/huge_support.dart')
      ..createSync()
      ..writeAsStringSync(List.filled(601, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckAppTestSupportFileSize(
      temp.path,
      allowlistPaths: const <String>[],
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('huge_support.dart'));
  });

  test('fails on stale allowlist entry that is now under the cap', () {
    final temp =
        Directory.systemTemp.createTempSync('check_app_support_stale_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/app/test/support').createSync(recursive: true);
    const relative = 'app/test/support/shrunk_support.dart';
    File('${temp.path}/$relative')
      ..createSync()
      ..writeAsStringSync('void main() {}\n');

    final logs = <String>[];
    final code = runCheckAppTestSupportFileSize(
      temp.path,
      allowlistPaths: const [relative],
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('stale allowlist'));
  });
}
