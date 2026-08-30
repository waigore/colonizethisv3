import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_hive_init.dart';

const _kHarnessOnly = '''
import 'package:colonizethis_app/config/constants.dart';
import 'package:hive/hive.dart';

Future<void> openAppTestHiveBox({required String suiteId}) async {
  Hive.init('./.dart_tool/test_hive_\$suiteId');
  await Hive.openBox<dynamic>(HiveBoxNames.games);
}
''';

const _kDecoyInline = '''
import 'package:hive/hive.dart';

void main() {
  Hive.init('./.dart_tool/test_hive_decoy');
}
''';

void _writeAppTestFile(Directory temp, String relativePath, String contents) {
  File('${temp.path}/$relativePath')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  test('passes when only the approved harness calls Hive.init', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_hive_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeAppTestFile(
      temp,
      'app/test/app_test_hive_harness.dart',
      _kHarnessOnly,
    );
    _writeAppTestFile(
      temp,
      'app/test/some_widget_test.dart',
      "void main() {}",
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateHiveInit(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0);
    expect(logs.join('\n'), contains('no duplicate Hive.init'));
  });

  test('fails when Hive.init is reintroduced outside the harness', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_hive_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeAppTestFile(
      temp,
      'app/test/app_test_hive_harness.dart',
      _kHarnessOnly,
    );
    _writeAppTestFile(temp, 'app/test/decoy_hive_test.dart', _kDecoyInline);

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateHiveInit(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('decoy_hive_test.dart'));
  });
}
