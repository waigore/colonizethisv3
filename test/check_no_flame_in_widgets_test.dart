import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_no_flame_in_widgets.dart';

void main() {
  test('fails when app/lib/widgets directly imports Flame', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_no_flame_in_widgets_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File('${temp.path}/app/lib/widgets/ct_panel.dart')
      ..createSync(recursive: true);
    violatingFile.writeAsStringSync(
      "import 'package:flame/widgets.dart';\nclass A {}\n",
    );

    final logs = <String>[];
    final code = runCheckNoFlameInWidgets(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('ct_panel.dart:1'));
  });

  test('passes when widgets imports do not include Flame', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_no_flame_in_widgets_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final okFile = File('${temp.path}/app/lib/widgets/ct_panel.dart')
      ..createSync(recursive: true);
    okFile.writeAsStringSync(
      "export '../features/game/widgets/chrome/ct_panel.dart';\n",
    );

    final code = runCheckNoFlameInWidgets(temp.path);
    expect(code, 0);
  });
}
