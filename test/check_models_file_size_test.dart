import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_models_file_size.dart';

const _srcRel = 'packages/colonizethis_models/lib/src';

void main() {
  test('passes for the real colonizethis_models source tree', () {
    final logs = <String>[];
    final code = runCheckModelsFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every colonizethis_models lib/src file must stay at or below '
          '${maxModelsFileNonCommentLinesForTests()} non-comment lines '
          '(grandfathered baseline excepted).\n${logs.join('\n')}',
    );
  });

  test('grandfathered real offenders still exist (allowlist not stale)', () {
    for (final relativePath in modelsFileSizeGrandfatheredForTests) {
      expect(
        File('${Directory.current.path}/$relativePath').existsSync(),
        isTrue,
        reason:
            'Grandfathered entry $relativePath must exist; remove it from the '
            'allowlist once the file is split below the cap.',
      );
    }
  });

  test('fails when a non-generated models file exceeds the cap', () {
    final temp = Directory.systemTemp.createTempSync('check_models_size_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);
    File('${temp.path}/$_srcRel/huge.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(501, 'final x = 1;').join('\n'));

    final logs = <String>[];
    final code = runCheckModelsFileSize(
      temp.path,
      grandfatheredPaths: const <String>[],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge.dart'));
    expect(logs.join('\n'), contains('non-comment lines > 500'));
  });

  test('does not count comment-only lines toward the cap', () {
    final temp = Directory.systemTemp.createTempSync('check_models_size_cmt_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);
    // 600 comment lines + a single code line is well under the cap.
    final lines = <String>[
      for (var i = 0; i < 600; i++) '// comment $i',
      'final x = 1;',
    ];
    File('${temp.path}/$_srcRel/comments.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(lines.join('\n'));

    final code = runCheckModelsFileSize(
      temp.path,
      grandfatheredPaths: const <String>[],
    );
    expect(code, 0);
  });

  test('ignores generated files over the cap', () {
    final temp = Directory.systemTemp.createTempSync('check_models_size_gen_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);
    File('${temp.path}/$_srcRel/huge.g.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(501, 'final x = 1;').join('\n'));

    final code = runCheckModelsFileSize(
      temp.path,
      grandfatheredPaths: const <String>[],
    );
    expect(code, 0);
  });

  test('skips an over-cap file listed in the grandfather allowlist', () {
    final temp = Directory.systemTemp.createTempSync('check_models_size_gf_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);
    const grandfatheredRel = '$_srcRel/legacy.dart';
    File('${temp.path}/$grandfatheredRel')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(501, 'final x = 1;').join('\n'));

    final code = runCheckModelsFileSize(
      temp.path,
      grandfatheredPaths: const [grandfatheredRel],
    );
    expect(code, 0);
  });

  test('fails when a grandfather entry no longer exists', () {
    final temp = Directory.systemTemp.createTempSync('check_models_size_stale_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);

    final logs = <String>[];
    final code = runCheckModelsFileSize(
      temp.path,
      grandfatheredPaths: const ['$_srcRel/gone.dart'],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('stale grandfather'));
    expect(logs.join('\n'), contains('gone.dart'));
  });

  test('fails when the models lib/src directory is missing', () {
    final temp = Directory.systemTemp.createTempSync('check_models_size_nodir_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckModelsFileSize(
      temp.path,
      grandfatheredPaths: const <String>[],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('not found'));
  });

  test('only checks provided target files when a target list is set', () {
    final temp = Directory.systemTemp.createTempSync('check_models_size_tgt_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_srcRel').createSync(recursive: true);
    File('${temp.path}/$_srcRel/large_untargeted.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(501, 'final x = 1;').join('\n'));
    File('${temp.path}/$_srcRel/small_targeted.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(10, 'final x = 1;').join('\n'));

    final code = runCheckModelsFileSize(
      temp.path,
      grandfatheredPaths: const <String>[],
      targetFiles: const ['$_srcRel/small_targeted.dart'],
    );
    expect(code, 0);
  });
}
