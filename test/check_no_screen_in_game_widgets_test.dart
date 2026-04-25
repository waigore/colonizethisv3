import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_no_screen_in_game_widgets.dart';

void main() {
  test('fails when game widgets contains a *_screen.dart file', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_no_screen_in_game_widgets_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File(
      '${temp.path}/app/lib/features/game/widgets/technology_screen.dart',
    )..createSync(recursive: true);
    violatingFile.writeAsStringSync('class TechnologyScreen {}\n');

    final logs = <String>[];
    final code = runCheckNoScreenInGameWidgets(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('technology_screen.dart'));
  });

  test('passes when game widgets has no *_screen.dart files', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_no_screen_in_game_widgets_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final okFile = File(
      '${temp.path}/app/lib/features/game/widgets/technology_panel.dart',
    )..createSync(recursive: true);
    okFile.writeAsStringSync('class TechnologyPanel {}\n');

    final code = runCheckNoScreenInGameWidgets(temp.path);
    expect(code, 0);
  });
}
