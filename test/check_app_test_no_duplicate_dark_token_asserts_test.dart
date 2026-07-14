import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_dark_token_asserts.dart';

void _write(Directory temp, String name, String contents) {
  File('${temp.path}/app/test/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  test('passes when suites call shared support helpers', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_dark_token_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    Directory('${temp.path}/app/test/support').createSync(recursive: true);
    File(
      '${temp.path}/app/test/support/editorial_monocle_dark_token_assertions.dart',
    )
      ..createSync()
      ..writeAsStringSync(
        'void expectMutedSingleSource(Object? a, Object b, String c) {}\n'
        'void expectMutedObfuscated(Object w, {required String context}) {}\n'
        'void expectEditorialMonocleDarkChrome(Object t) {}\n',
      );
    _write(
      temp,
      'suite_test.dart',
      "import 'support/editorial_monocle_dark_token_assertions.dart';\n"
      'void main() {\n'
      '  expectMutedSingleSource(null, Object(), "x");\n'
      '}\n',
    );

    final code = runCheckAppTestNoDuplicateDarkTokenAsserts(temp.path);
    expect(code, 0);
  });

  test('fails when a suite re-declares a private muted expect helper', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_dark_token_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _write(
      temp,
      'fork_test.dart',
      'void _expectMutedSingleSource(Object? a, Object b, String c) {}\n'
      'void main() {}\n',
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateDarkTokenAsserts(
      temp.path,
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('_expectMutedSingleSource'));
  });

  test('passes on the real app/test tree', () {
    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateDarkTokenAsserts(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(code, 0, reason: logs.join('\n'));
  });
}
