import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_widget_imports.dart';

void main() {
  test('fails when non-allowlisted widget imports features path', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_widget_imports_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File('${temp.path}/app/lib/widgets/bad_widget.dart')
      ..createSync(recursive: true);
    violatingFile.writeAsStringSync(
      "import '../features/game/flame/ct_region_map_game.dart';\nclass A {}\n",
    );

    final logs = <String>[];
    final code = runCheckAppWidgetImports(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('bad_widget.dart:1'));
  });

  test('fails when non-allowlisted widget exports package features path', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_widget_imports_pkg_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File('${temp.path}/app/lib/widgets/bad_export.dart')
      ..createSync(recursive: true);
    violatingFile.writeAsStringSync(
      "export 'package:colonizethis_app/features/game/widgets/a.dart';\n",
    );

    expect(runCheckAppWidgetImports(temp.path, err: (_) {}), 1);
  });

  test('passes for known allowlisted bridge widget', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_widget_imports_allowlist_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final allowlistedFile = File('${temp.path}/app/lib/widgets/ct_panel.dart')
      ..createSync(recursive: true);
    allowlistedFile.writeAsStringSync(
      "export '../features/game/widgets/chrome/ct_panel.dart';\n",
    );

    expect(runCheckAppWidgetImports(temp.path), 0);
  });

  test('ignores line comments and non-feature imports', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_widget_imports_comment_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final okFile = File('${temp.path}/app/lib/widgets/ok.dart')
      ..createSync(recursive: true);
    okFile.writeAsStringSync(
      "// import '../features/game/flame/ct_region_map_game.dart';\n"
      "import 'package:flutter/widgets.dart';\n"
      'class A {}\n',
    );

    expect(runCheckAppWidgetImports(temp.path), 0);
  });
}
