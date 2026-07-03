import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_map_lib_file_size.dart';

const _genRoot = 'packages/colonizethis_map/lib/src/gen';
const _viewRoot = 'packages/colonizethis_map/lib/src/view';
const _renderRoot = 'packages/colonizethis_map/lib/src/render';

void main() {
  test('passes for the real gen/view/render layers on dev', () {
    final logs = <String>[];
    final code = runCheckMapLibFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every colonizethis_map gen/view/render source file must stay at or below '
          '${maxMapLibFileNonCommentLinesForTests()} non-comment lines.\n'
          '${logs.join('\n')}',
    );
  });

  test('the canonical scanned roots exist (gate cannot silently rot)', () {
    for (final relativeRoot in mapLibFileSizeScanRoots) {
      expect(
        Directory('${Directory.current.path}/$relativeRoot').existsSync(),
        isTrue,
        reason:
            'Scanned root $relativeRoot must exist; update '
            'mapLibFileSizeScanRoots if the map lib layer moved.',
      );
    }
  });

  test('fails when a gen file exceeds the 500 non-comment-line cap', () {
    final temp = Directory.systemTemp.createTempSync('check_map_lib_size_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File('${temp.path}/$_genRoot/big_pass.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(501, 'final x = 1;').join('\n'));
    Directory('${temp.path}/$_viewRoot').createSync(recursive: true);
    Directory('${temp.path}/$_renderRoot').createSync(recursive: true);

    final logs = <String>[];
    final code = runCheckMapLibFileSize(
      temp.path,
      scanRoots: const [_genRoot, _viewRoot, _renderRoot],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('big_pass.dart'));
    expect(logs.join('\n'), contains('non-comment lines > 500'));
  });

  test('passes a gen file at exactly the cap (500 non-comment lines)', () {
    final temp = Directory.systemTemp.createTempSync('check_map_lib_size_edge_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File('${temp.path}/$_genRoot/edge_pass.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(500, 'final x = 1;').join('\n'));
    Directory('${temp.path}/$_viewRoot').createSync(recursive: true);
    Directory('${temp.path}/$_renderRoot').createSync(recursive: true);

    final code = runCheckMapLibFileSize(
      temp.path,
      scanRoots: const [_genRoot, _viewRoot, _renderRoot],
    );
    expect(code, 0);
  });

  test('does not count comment-only lines toward the cap', () {
    final temp = Directory.systemTemp.createTempSync('check_map_lib_size_cmt_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final lines = <String>[
      for (var i = 0; i < 600; i++) '// comment $i',
      'final x = 1;',
    ];
    File('${temp.path}/$_genRoot/comment_pass.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(lines.join('\n'));
    Directory('${temp.path}/$_viewRoot').createSync(recursive: true);
    Directory('${temp.path}/$_renderRoot').createSync(recursive: true);

    final code = runCheckMapLibFileSize(
      temp.path,
      scanRoots: const [_genRoot, _viewRoot, _renderRoot],
    );
    expect(code, 0);
  });

  test('fails when a scanned root is missing (anti-rot existence check)', () {
    final temp = Directory.systemTemp.createTempSync('check_map_lib_size_gone_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckMapLibFileSize(
      temp.path,
      scanRoots: const [_genRoot, _viewRoot, _renderRoot],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('not found'));
    expect(logs.join('\n'), contains(_genRoot));
  });
}
