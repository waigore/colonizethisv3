import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_event_handler_scope_logic_boundary.dart';

void main() {
  test(
    'runCheckAppEventHandlerScopeLogicBoundary fails when scope imports game logic directly',
    () {
      final tempDir = Directory.systemTemp.createTempSync(
        'check_app_event_handler_scope_logic_boundary_test_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final targetPath = p.join(
        tempDir.path,
        'app',
        'lib',
        'core',
        'services',
        'app_event_handler_scope.dart',
      );
      File(targetPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:colonizethis_app/features/game/logic/some_logic.dart';
''');

      final stderrLines = <String>[];
      final code = runCheckAppEventHandlerScopeLogicBoundary(
        tempDir.path,
        err: stderrLines.add,
      );
      expect(code, 1);
      expect(
        stderrLines.join('\n'),
        contains('direct import from features/game/logic is disallowed'),
      );
    },
  );

  test(
    'runCheckAppEventHandlerScopeLogicBoundary passes when scope avoids game logic imports',
    () {
      final tempDir = Directory.systemTemp.createTempSync(
        'check_app_event_handler_scope_logic_boundary_test_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final targetPath = p.join(
        tempDir.path,
        'app',
        'lib',
        'core',
        'services',
        'app_event_handler_scope.dart',
      );
      File(targetPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:colonizethis_app/app.dart';
import 'package:flutter/widgets.dart';
''');

      final stdoutLines = <String>[];
      final code = runCheckAppEventHandlerScopeLogicBoundary(
        tempDir.path,
        info: stdoutLines.add,
      );
      expect(code, 0);
      expect(stdoutLines.join('\n'), contains('no violations found'));
    },
  );
}
