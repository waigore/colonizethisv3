import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_catalog_widgets_file_size.dart';

void main() {
  test('fails when a catalog widget file exceeds 300 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_catalog_widgets_file_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File('${temp.path}/app/lib/widgets/huge_ct.dart')
      ..createSync(recursive: true);
    violatingFile.writeAsStringSync(List.filled(301, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckAppCatalogWidgetsFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge_ct.dart'));
    expect(logs.join('\n'), contains('301 physical lines > 300'));
  });

  test('fails when catalog widgets directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_catalog_widgets_file_size_no_dir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckAppCatalogWidgetsFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('widgets not found'));
  });

  test('passes when all catalog widget files are at or below 300 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_catalog_widgets_file_size_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final okFile = File('${temp.path}/app/lib/widgets/panel.dart')
      ..createSync(recursive: true);
    okFile.writeAsStringSync(List.filled(300, '// line').join('\n'));

    final code = runCheckAppCatalogWidgetsFileSize(temp.path);
    expect(code, 0);
  });
}
