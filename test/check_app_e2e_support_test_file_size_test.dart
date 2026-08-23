import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_e2e_support_test_file_size.dart';

void main() {
  test(
    'passes for the real e2e-support test tree with shrink-only allowlist',
    () {
      final logs = <String>[];
      final code = runCheckAppE2eSupportTestFileSize(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(
        code,
        0,
        reason:
            'Every packages/colonizethis_app_e2e_support/test file must stay '
            'at or below ${maxAppE2eSupportTestPhysicalLinesForTests()} '
            'physical lines (allowlisted baseline excepted).\n'
            '${logs.join('\n')}',
      );
    },
  );

  test('allowlisted offenders still exceed the cap (shrink-only)', () {
    for (final relativePath in appE2eSupportTestFileSizeAllowlistForTests) {
      final file = File('${Directory.current.path}/$relativePath');
      expect(file.existsSync(), isTrue, reason: relativePath);
      final lines = file.readAsLinesSync().length;
      expect(
        lines,
        greaterThan(maxAppE2eSupportTestPhysicalLinesForTests()),
        reason:
            '$relativePath must remain over the cap while allowlisted '
            '(got $lines).',
      );
    }
  });

  test('fails when a non-allowlisted file exceeds the cap', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_e2e_support_test_size_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory(
      '${temp.path}/packages/colonizethis_app_e2e_support/test',
    ).createSync(recursive: true);
    File(
        '${temp.path}/packages/colonizethis_app_e2e_support/test/huge_test.dart',
      )
      ..createSync()
      ..writeAsStringSync(List.filled(301, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckAppE2eSupportTestFileSize(
      temp.path,
      allowlistPaths: const <String>[],
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('huge_test.dart'));
  });

  test('fails on stale allowlist entry that is now under the cap', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_e2e_support_test_stale_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory(
      '${temp.path}/packages/colonizethis_app_e2e_support/test',
    ).createSync(recursive: true);
    const relative =
        'packages/colonizethis_app_e2e_support/test/shrunk_test.dart';
    File('${temp.path}/$relative')
      ..createSync()
      ..writeAsStringSync('void main() {}\n');

    final logs = <String>[];
    final code = runCheckAppE2eSupportTestFileSize(
      temp.path,
      allowlistPaths: const [relative],
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('stale allowlist'));
  });
}
