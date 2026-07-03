import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_diplomacy_host.dart';

void _writeTestFile(Directory temp, String name, String contents) {
  File('${temp.path}/app/test/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  test('passes when no local _EventHandlingWrapper is declared', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_diplomacy_host_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeTestFile(
      temp,
      'diplomacy_panel_test.dart',
      "import 'support/diplomacy_panel_test_support.dart';\n",
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateDiplomacyHost(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0);
    expect(logs.join('\n'), contains('no duplicated bus-dialog hosts found'));
  });

  test('fails when _EventHandlingWrapper is reintroduced', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_diplomacy_host_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeTestFile(
      temp,
      'diplomacy_panel_test.dart',
      '''
class _EventHandlingWrapper extends StatefulWidget {
  @override
  State<_EventHandlingWrapper> createState() => throw UnimplementedError();
}
''',
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateDiplomacyHost(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains('private class "_EventHandlingWrapper" duplicates'),
    );
  });

  test('does not fire on support harness definitions', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_diplomacy_host_support_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    File('${temp.path}/app/test/support/diplomacy_panel_test_support.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
class _EventHandlingWrapper extends StatefulWidget {
  @override
  State<_EventHandlingWrapper> createState() => throw UnimplementedError();
}
''');

    final code = runCheckAppTestNoDuplicateDiplomacyHost(temp.path);
    expect(code, 0);
  });
}
