import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_map_test_file_size.dart';

const _mapTestsRelativePath = 'packages/colonizethis_map/test';

void main() {
  test('passes for the real map test tree on dev', () {
    final logs = <String>[];
    final code = runCheckMapTestFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every colonizethis_map test file must stay at or below '
          '${maxMapTestFilePhysicalLinesForTests()} physical lines.\n'
          '${logs.join('\n')}',
    );
  });

  test('ceiling is 250 after wave-7 ratchet (#4561)', () {
    expect(maxMapTestFilePhysicalLinesForTests(), 250);
  });

  test('grandfather allowlist is empty after wave-7 densify', () {
    expect(mapTestFileSizeGrandfathered, isEmpty);
  });

  test('fails when a map test file exceeds the 250 physical-line cap', () {
    final temp = Directory.systemTemp.createTempSync('check_map_test_size_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File('${temp.path}/$_mapTestsRelativePath/big_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(251, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckMapTestFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('big_test.dart'));
    expect(logs.join('\n'), contains('> 250'));
  });
}
