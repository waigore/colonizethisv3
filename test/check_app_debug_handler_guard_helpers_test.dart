import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_debug_handler_guard_helpers.dart';

void main() {
  test('passes on the repository debug handlers', () {
    final repoRoot = Directory.current.path;
    expect(runCheckAppDebugHandlerGuardHelpers(repoRoot), 0);
  });

  test('fails when a handler inlines a guard string', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_debug_handler_guard_helpers_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    final servicesDir = Directory(
      '${temp.path}/app/lib/core/services',
    )..createSync(recursive: true);

    File(
      '${servicesDir.path}/app_event_handler_debug_offender.dart',
    ).writeAsStringSync('''
typedef DebugCommandResult = ({Object? game, String message});

DebugCommandResult applyDebugOffender({Object? currentGame}) {
  if (currentGame == null) {
    return (game: null, message: 'Debug spawn ignored: no active game.');
  }
  return (game: currentGame, message: 'ok');
}
''');

    final logs = <String>[];
    final code = runCheckAppDebugHandlerGuardHelpers(
      temp.path,
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(logs.join('\n'), contains('no active game.'));
  });

  test('passes when handlers use shared helper calls', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_debug_handler_guard_helpers_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    final servicesDir = Directory(
      '${temp.path}/app/lib/core/services',
    )..createSync(recursive: true);

    File(
      '${servicesDir.path}/app_event_handler_debug_clean.dart',
    ).writeAsStringSync('''
import 'debug_command_helpers.dart';

DebugCommandResult applyDebugClean({Object? currentGame}) {
  if (currentGame == null) {
    return debugNoActiveGame(DebugCommandLabel.spawn);
  }
  return (game: currentGame, message: 'ok');
}
''');

    final code = runCheckAppDebugHandlerGuardHelpers(temp.path);
    expect(code, 0);
  });
}
