// Refs #3279 — guards `repo.app_game_panel_mixin` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_game_panel_mixin.dart';

void main() {
  group('repo.app_game_panel_mixin', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAppGamePanelMixin(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_app_game_panel_mixin: all fully-shaped game panels mix in '
          'GamePanelMixin.',
        ),
      );
    });

    test('fails when a fully-shaped panel omits `with GamePanelMixin`', () {
      final temp = Directory.systemTemp.createTempSync('game_panel_mixin_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'sample_panel.dart')).writeAsStringSync(
        'class SamplePanel {\n'
        '  const SamplePanel({\n'
        '    required this.game,\n'
        '    required this.bus,\n'
        '    this.readOnly = false,\n'
        '  });\n'
        '  final Object game;\n'
        '  final Object bus;\n'
        '  final bool readOnly;\n'
        '}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAppGamePanelMixin(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('sample_panel.dart'));
      expect(errLogs.join('\n'), contains('SamplePanel'));
      expect(errLogs.join('\n'), contains('GamePanelMixin'));
    });

    test('passes when a fully-shaped panel adopts `with GamePanelMixin`', () {
      final temp = Directory.systemTemp.createTempSync('game_panel_mixin_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'sample_panel.dart')).writeAsStringSync(
        'class SamplePanel extends StatefulWidget with GamePanelMixin {\n'
        '  const SamplePanel({\n'
        '    required this.game,\n'
        '    required this.humanPlayerId,\n'
        '    required this.bus,\n'
        '    this.readOnly = false,\n'
        '  });\n'
        '  final Object game;\n'
        '  final String humanPlayerId;\n'
        '  final Object bus;\n'
        '  final bool readOnly;\n'
        '}\n',
      );

      final code = runCheckAppGamePanelMixin(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts panels missing bus / readOnly (Production / Technology)', () {
      final temp = Directory.systemTemp.createTempSync('game_panel_mixin_excl_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      // Mirrors ProductionPanel / TechnologyPanel: `game` + `player`, no
      // `bus` / `readOnly`, so the full contract does not apply.
      File(p.join(widgetsDir.path, 'production_panel.dart')).writeAsStringSync(
        'class ProductionPanel {\n'
        '  const ProductionPanel({required this.game, required this.player});\n'
        '  final Object game;\n'
        '  final Object player;\n'
        '}\n',
      );

      final code = runCheckAppGamePanelMixin(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts panels without a game parameter (PauseMenuPanel)', () {
      final temp = Directory.systemTemp.createTempSync('game_panel_mixin_busy_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'pause_menu_panel.dart')).writeAsStringSync(
        'class PauseMenuPanel {\n'
        '  const PauseMenuPanel({required this.bus, this.readOnly = false});\n'
        '  final Object bus;\n'
        '  final bool readOnly;\n'
        '}\n',
      );

      final code = runCheckAppGamePanelMixin(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts private _*Panel helpers even with the full param set', () {
      final temp = Directory.systemTemp.createTempSync('game_panel_mixin_priv_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'deal_book.dart')).writeAsStringSync(
        'class _DealBookPanel {\n'
        '  const _DealBookPanel({\n'
        '    required this.game,\n'
        '    required this.bus,\n'
        '    this.readOnly = false,\n'
        '  });\n'
        '  final Object game;\n'
        '  final Object bus;\n'
        '  final bool readOnly;\n'
        '}\n',
      );

      final code = runCheckAppGamePanelMixin(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}
