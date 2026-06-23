import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_debug_init.dart';

const _kCallingTestContents = '''
void main() {
  final result = getDebugInitGameResult();
  print(result);
}
''';

const _kCleanTestContents = '''
void main() {
  print('no debug init here');
}
''';

const _kCommentOnlyContents = '''
// This file mentions getDebugInitGameResult() only in a comment.
void main() {
  print('still clean');
}
''';

File _writeAppTest(Directory temp, String name, String contents) {
  return File('${temp.path}/app/test/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  test('passes when no app/test file calls getDebugInitGameResult()', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_debug_init_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeAppTest(temp, 'clean_test.dart', _kCleanTestContents);

    final logs = <String>[];
    final code = runCheckAppTestNoDebugInit(
      temp.path,
      allowlist: const <String>{},
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0);
    expect(
      logs.join('\n'),
      contains('no disallowed getDebugInitGameResult() usage'),
    );
  });

  test('fails when a non-allowlisted file calls getDebugInitGameResult()', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_debug_init_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeAppTest(temp, 'offender_test.dart', _kCallingTestContents);

    final logs = <String>[];
    final code = runCheckAppTestNoDebugInit(
      temp.path,
      allowlist: const <String>{},
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains('app/test/offender_test.dart:2: calls getDebugInitGameResult()'),
    );
  });

  test('passes when the calling file is in the allowlist', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_debug_init_allow_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeAppTest(temp, 'allowed_test.dart', _kCallingTestContents);

    final code = runCheckAppTestNoDebugInit(
      temp.path,
      allowlist: const <String>{'app/test/allowed_test.dart'},
    );

    expect(code, 0);
  });

  test('ignores comment-only mentions of the symbol', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_debug_init_comment_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeAppTest(temp, 'comment_test.dart', _kCommentOnlyContents);

    final code = runCheckAppTestNoDebugInit(
      temp.path,
      allowlist: const <String>{},
    );

    expect(code, 0);
  });
}
