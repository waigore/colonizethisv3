import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_map_lib_file_size_headroom.dart';

const _genRoot = 'packages/colonizethis_map/lib/src/gen';
const _viewRoot = 'packages/colonizethis_map/lib/src/view';
const _renderRoot = 'packages/colonizethis_map/lib/src/render';

void main() {
  test('passes for the real gen/view/render layers on dev', () {
    final logs = <String>[];
    final code = runCheckMapLibFileSizeHeadroom(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every colonizethis_map gen/view/render source file must stay at or below '
          '${maxMapLibFileHeadroomNonCommentLinesForTests()} non-comment lines.\n'
          '${logs.join('\n')}',
    );
  });

  test('ceiling is 300 after wave-6 headroom ratchet (#4371)', () {
    expect(mapLibFileSizeHeadroomCeiling, 300);
  });

  test('grandfather allowlist is empty after wave-5 splits', () {
    expect(mapLibFileSizeHeadroomGrandfathered, isEmpty);
  });

  test('fails when a gen file exceeds the 300 non-comment-line headroom', () {
    final temp =
        Directory.systemTemp.createTempSync('check_map_lib_headroom_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File('${temp.path}/$_genRoot/big_pass.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(301, 'final x = 1;').join('\n'));
    Directory('${temp.path}/$_viewRoot').createSync(recursive: true);
    Directory('${temp.path}/$_renderRoot').createSync(recursive: true);

    final logs = <String>[];
    final code = runCheckMapLibFileSizeHeadroom(
      temp.path,
      scanRoots: const [_genRoot, _viewRoot, _renderRoot],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('big_pass.dart'));
    expect(logs.join('\n'), contains('non-comment lines > 300'));
  });

  test('passes a gen file at exactly the headroom cap (300 non-comment lines)',
      () {
    final temp =
        Directory.systemTemp.createTempSync('check_map_lib_headroom_edge_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File('${temp.path}/$_genRoot/edge_pass.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(300, 'final x = 1;').join('\n'));
    Directory('${temp.path}/$_viewRoot').createSync(recursive: true);
    Directory('${temp.path}/$_renderRoot').createSync(recursive: true);

    final code = runCheckMapLibFileSizeHeadroom(
      temp.path,
      scanRoots: const [_genRoot, _viewRoot, _renderRoot],
    );
    expect(code, 0);
  });

  test('skips shrink-only grandfather entries', () {
    final temp =
        Directory.systemTemp.createTempSync('check_map_lib_headroom_grand_');
    addTearDown(() => temp.deleteSync(recursive: true));

    File('${temp.path}/$_genRoot/grandfathered.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(400, 'final x = 1;').join('\n'));
    File('${temp.path}/$_genRoot/ok.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('final x = 1;\n');
    Directory('${temp.path}/$_viewRoot').createSync(recursive: true);
    Directory('${temp.path}/$_renderRoot').createSync(recursive: true);

    final logs = <String>[];
    final code = runCheckMapLibFileSizeHeadroom(
      temp.path,
      scanRoots: const [_genRoot, _viewRoot, _renderRoot],
      grandfatheredPaths: const [
        'packages/colonizethis_map/lib/src/gen/grandfathered.dart',
      ],
      info: logs.add,
      err: logs.add,
    );
    expect(code, 0, reason: logs.join('\n'));
  });

  test('fails when a scanned root is missing (anti-rot existence check)', () {
    final temp =
        Directory.systemTemp.createTempSync('check_map_lib_headroom_gone_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckMapLibFileSizeHeadroom(
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
