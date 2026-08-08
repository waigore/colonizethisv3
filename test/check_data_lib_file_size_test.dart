import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_data_lib_file_size.dart';

const _srcRel = 'packages/colonizethis_data/lib/src';

void main() {
  test('passes for the real colonizethis_data source tree', () {
    final logs = <String>[];
    final code = runCheckDataLibFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every colonizethis_data lib/src file must stay at or below '
          '${maxDataLibFilePhysicalLinesForTests()} physical lines '
          '(generated *.gen.dart skipped; Refs #4292).\n'
          '${logs.join('\n')}',
    );
  });

  test('grandfather allowlist is empty after #4292 wave-5 splits', () {
    expect(dataFileSizeGrandfatheredForTests, isEmpty);
  });

  test('fails when a non-generated data file exceeds the cap', () {
    final temp = Directory.systemTemp.createTempSync('check_data_size_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);
    File('${temp.path}/$_srcRel/huge.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(401, 'final x = 1;').join('\n'));

    final logs = <String>[];
    final code = runCheckDataLibFileSize(
      temp.path,
      grandfatheredPaths: const <String>[],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge.dart'));
    expect(logs.join('\n'), contains('physical lines > 400'));
  });

  test('skips an over-cap generated *.gen.dart file', () {
    final temp = Directory.systemTemp.createTempSync('check_data_size_gen_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);
    File('${temp.path}/$_srcRel/tech_effect_summary_embed.gen.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(401, 'final x = 1;').join('\n'));

    final code = runCheckDataLibFileSize(
      temp.path,
      grandfatheredPaths: const <String>[],
    );
    expect(code, 0);
  });

  test('skips an over-cap file listed in the grandfather allowlist', () {
    final temp = Directory.systemTemp.createTempSync('check_data_size_gf_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);
    const grandfatheredRel = '$_srcRel/legacy.dart';
    File('${temp.path}/$grandfatheredRel')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(401, 'final x = 1;').join('\n'));

    final code = runCheckDataLibFileSize(
      temp.path,
      grandfatheredPaths: const [grandfatheredRel],
    );
    expect(code, 0);
  });

  test('fails when a grandfather entry no longer exists', () {
    final temp = Directory.systemTemp.createTempSync('check_data_size_stale_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);

    final logs = <String>[];
    final code = runCheckDataLibFileSize(
      temp.path,
      grandfatheredPaths: const ['$_srcRel/missing.dart'],
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('stale grandfather'));
    expect(logs.join('\n'), contains('missing.dart'));
  });
}
