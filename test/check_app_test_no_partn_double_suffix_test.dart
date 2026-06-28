import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_partn_double_suffix.dart';

void _writeTestFile(Directory temp, String name) {
  File('${temp.path}/app/test/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync("void main() {}\n");
}

void main() {
  test('isDoubleSuffixPartFileName flags the double `_test` suffix only', () {
    expect(
      isDoubleSuffixPartFileName('military_units_panel_test_part1_test.dart'),
      isTrue,
    );
    expect(
      isDoubleSuffixPartFileName('naval_units_panel_test_part12_test.dart'),
      isTrue,
    );
    // Clean convention must pass.
    expect(
      isDoubleSuffixPartFileName('military_units_panel_part1_test.dart'),
      isFalse,
    );
    expect(
      isDoubleSuffixPartFileName('province_panel_draft_orders_part2_test.dart'),
      isFalse,
    );
    // Unrelated plain test files must pass.
    expect(
      isDoubleSuffixPartFileName('trade_screen_320dp_min_viewport_test.dart'),
      isFalse,
    );
  });

  test('passes on the clean <family>_part<N>_test.dart convention', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_partn_double_suffix_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeTestFile(temp, 'military_units_panel_part1_test.dart');
    _writeTestFile(temp, 'province_panel_draft_orders_part2_test.dart');
    _writeTestFile(temp, 'trade_screen_320dp_min_viewport_test.dart');

    final logs = <String>[];
    final code = runCheckAppTestNoPartNDoubleSuffix(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0);
    expect(
      logs.join('\n'),
      contains('<family>_part<N>_test.dart convention'),
    );
  });

  test('fails when a _test_partN_test.dart double-suffix name is present', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_partn_double_suffix_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeTestFile(temp, 'military_units_panel_test_part1_test.dart');

    final logs = <String>[];
    final code = runCheckAppTestNoPartNDoubleSuffix(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains(
        'app/test/military_units_panel_test_part1_test.dart: double `_test` '
        'split-family fragment is disallowed',
      ),
    );
  });

  test('reports multiple violations, sorted', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_partn_double_suffix_multi_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeTestFile(temp, 'a_panel_test_part1_test.dart');
    _writeTestFile(temp, 'b_panel_test_part2_test.dart');

    final logs = <String>[];
    final code = runCheckAppTestNoPartNDoubleSuffix(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    final joined = logs.join('\n');
    expect(joined, contains('app/test/a_panel_test_part1_test.dart:'));
    expect(joined, contains('app/test/b_panel_test_part2_test.dart:'));
  });

  test('passes when app/test is absent (partial checkout)', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_partn_double_suffix_absent_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final code = runCheckAppTestNoPartNDoubleSuffix(temp.path);
    expect(code, 0);
  });
}
