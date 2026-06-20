import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_logic_source_file_size.dart';

void main() {
  test('passes when only baseline offenders exceed 500 lines', () {
    final code = runCheckLogicSourceFileSize(
      Directory.current.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails when a new lib/src file exceeds 500 physical lines', () {
    final temp = Directory.systemTemp.createTempSync('logic_src_size_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final baseline = File('${temp.path}/tool/logic_source_file_size_baseline.json')
      ..createSync(recursive: true);
    baseline.writeAsStringSync('[]');

    final violating = File(
      '${temp.path}/packages/colonizethis_logic/lib/src/world/huge.dart',
    )..createSync(recursive: true);
    violating.writeAsStringSync(List.filled(501, '// line').join('\n'));

    final code = runCheckLogicSourceFileSize(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });
}
