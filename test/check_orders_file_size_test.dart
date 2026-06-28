import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_orders_file_size.dart';

const _ordersLibDir = 'packages/colonizethis_orders/lib/src/orders';

void main() {
  test('passes for the real gated orders hot files on dev', () {
    final logs = <String>[];
    final code = runCheckOrdersFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'orders_application.dart and orders_application_completed_work.dart '
          'must stay at or below '
          '${maxOrdersFileNonCommentLinesForTests()} non-comment lines.\n'
          '${logs.join('\n')}',
    );
  });

  test('the canonical gated files exist (gate cannot silently rot)', () {
    for (final relativePath in ordersFileSizeGatedFiles) {
      expect(
        File('${Directory.current.path}/$relativePath').existsSync(),
        isTrue,
        reason:
            'Gated file $relativePath must exist; update '
            'ordersFileSizeGatedFiles if the orders module moved.',
      );
    }
  });

  test('fails when a gated file exceeds the 1000 non-comment-line cap', () {
    final temp = Directory.systemTemp.createTempSync('check_orders_size_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    const gatedRel = '$_ordersLibDir/orders_application.dart';
    File('${temp.path}/$gatedRel')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(1001, 'final x = 1;').join('\n'));

    final logs = <String>[];
    final code = runCheckOrdersFileSize(
      temp.path,
      gatedFiles: const [gatedRel],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('orders_application.dart'));
    expect(logs.join('\n'), contains('non-comment lines > 1000'));
  });

  test('passes a gated file at exactly the cap (1000 non-comment lines)', () {
    final temp = Directory.systemTemp.createTempSync('check_orders_size_edge_');
    addTearDown(() => temp.deleteSync(recursive: true));

    const gatedRel = '$_ordersLibDir/orders_application.dart';
    File('${temp.path}/$gatedRel')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(1000, 'final x = 1;').join('\n'));

    final code = runCheckOrdersFileSize(
      temp.path,
      gatedFiles: const [gatedRel],
    );
    expect(code, 0);
  });

  test('does not count comment-only lines toward the cap', () {
    final temp = Directory.systemTemp.createTempSync('check_orders_size_cmt_');
    addTearDown(() => temp.deleteSync(recursive: true));

    const gatedRel = '$_ordersLibDir/orders_application.dart';
    final lines = <String>[
      for (var i = 0; i < 1100; i++) '// comment $i',
      'final x = 1;',
    ];
    File('${temp.path}/$gatedRel')
      ..createSync(recursive: true)
      ..writeAsStringSync(lines.join('\n'));

    final code = runCheckOrdersFileSize(
      temp.path,
      gatedFiles: const [gatedRel],
    );
    expect(code, 0);
  });

  test('fails when a gated file is missing (anti-rot existence check)', () {
    final temp = Directory.systemTemp.createTempSync('check_orders_size_gone_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckOrdersFileSize(
      temp.path,
      gatedFiles: const ['$_ordersLibDir/orders_application.dart'],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('not found'));
    expect(logs.join('\n'), contains('orders_application.dart'));
  });
}
