import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_logic_test_file_size.dart';

void main() {
  test('fails when a logic test file exceeds 250 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_logic_test_file_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File(
      '${temp.path}/packages/colonizethis_logic/test/huge_test.dart',
    )..createSync(recursive: true);
    violatingFile.writeAsStringSync(List.filled(251, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckLogicTestFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge_test.dart'));
    expect(logs.join('\n'), contains('251 physical lines > 250'));
  });

  test('fails when logic test directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_logic_test_file_size_no_dir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckLogicTestFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('test not found'));
  });

  test('passes when all logic test files are at or below 250 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_logic_test_file_size_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final okFile = File(
      '${temp.path}/packages/colonizethis_logic/test/ok_test.dart',
    )..createSync(recursive: true);
    okFile.writeAsStringSync(List.filled(250, '// line').join('\n'));

    final code = runCheckLogicTestFileSize(temp.path);
    expect(code, 0);
  });

  test('only checks provided target files when target list is set', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_logic_test_file_size_targets_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final largeUntargeted = File(
      '${temp.path}/packages/colonizethis_logic/test/large_untargeted_test.dart',
    )..createSync(recursive: true);
    largeUntargeted.writeAsStringSync(List.filled(251, '// line').join('\n'));

    final smallTargeted = File(
      '${temp.path}/packages/colonizethis_logic/test/small_targeted_test.dart',
    )..createSync(recursive: true);
    smallTargeted.writeAsStringSync(List.filled(10, '// line').join('\n'));

    final code = runCheckLogicTestFileSize(
      temp.path,
      targetFiles: const [
        'packages/colonizethis_logic/test/small_targeted_test.dart',
      ],
    );

    expect(code, 0);
  });
}
