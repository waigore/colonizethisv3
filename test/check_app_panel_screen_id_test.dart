// Refs #3279 — guards `repo.app_panel_screen_id` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_panel_screen_id.dart';

void main() {
  group('repo.app_panel_screen_id', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAppPanelScreenId(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_app_panel_screen_id: all game-bearing panels declare screenId.',
        ),
      );
    });

    test('fails when a game-bearing panel omits screenId', () {
      final temp = Directory.systemTemp.createTempSync('panel_screen_id_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'sample_panel.dart')).writeAsStringSync(
        'class SamplePanel {\n'
        '  const SamplePanel({required this.game});\n'
        '  final Object game;\n'
        '}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAppPanelScreenId(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('sample_panel.dart'));
      expect(errLogs.join('\n'), contains('SamplePanel'));
      expect(errLogs.join('\n'), contains('screenId'));
    });

    test('passes when a game-bearing panel declares static const screenId', () {
      final temp = Directory.systemTemp.createTempSync('panel_screen_id_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'sample_panel.dart')).writeAsStringSync(
        'class SamplePanel {\n'
        '  const SamplePanel({required this.game});\n'
        "  static const screenId = UiScreenIds.gameScreen;\n"
        '  final Object game;\n'
        '}\n',
      );

      final code = runCheckAppPanelScreenId(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts panels without a game parameter', () {
      final temp = Directory.systemTemp.createTempSync('panel_screen_id_busy_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      // Mirrors PauseMenuPanel / ObserveModeNotDefinedPanel: no `game` param.
      File(p.join(widgetsDir.path, 'placeholder_panel.dart')).writeAsStringSync(
        'class PlaceholderPanel {\n'
        '  const PlaceholderPanel({this.title});\n'
        '  final String? title;\n'
        '}\n',
      );

      final code = runCheckAppPanelScreenId(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts private _*Panel helpers even with a game parameter', () {
      final temp = Directory.systemTemp.createTempSync('panel_screen_id_priv_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'deal_book.dart')).writeAsStringSync(
        'class _DealBookPanel {\n'
        '  const _DealBookPanel({required this.game});\n'
        '  final Object game;\n'
        '}\n',
      );

      final code = runCheckAppPanelScreenId(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}
