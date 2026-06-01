import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_switchlisttile.dart';

void main() {
  group('runCheckAppNoMaterialSwitchListTile', () {
    test('passes when every features file composes CtSectionLabel + '
        'CtToggleSwitch (no SwitchListTile)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_switchlisttile_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/clean.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: const <Widget>[
      CtSectionLabel(label: 'Show overlay'),
      CtToggleSwitch(value: false),
    ]);
  }
}
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialSwitchListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test('fails when a feature file constructs SwitchListTile(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_switchlisttile_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_tile.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget tile() => SwitchListTile(
  title: const Text('Show overlay'),
  value: false,
  onChanged: (_) {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialSwitchListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('bad_tile.dart:3: SwitchListTile('));
      expect(logs.join('\n'), contains('CtToggleSwitch'));
    });

    test('fails for SwitchListTile.adaptive variant', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_switchlisttile_adaptive_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/adaptive.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget adaptive() => SwitchListTile.adaptive(
  title: const Text('Show overlay'),
  value: false,
  onChanged: (_) {},
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialSwitchListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('SwitchListTile.adaptive('));
    });

    test(
      'passes when SwitchListTile appears inside a // comment or /// dartdoc',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_switchlisttile_comment_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtSectionLabel + CtToggleSwitch over SwitchListTile( for toggle rows.
// SwitchListTile( must not appear in real code, but a // comment is fine.
class C {}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialSwitchListTile(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('does not flag identifiers that contain "SwitchListTile" without '
        'an opening paren (false-positive guard)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_switchlisttile_identifier_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/identifier.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

class FakeSwitchListTileProbe {
  static const String label = 'SwitchListTileProbe';
}
''');

      final code = runCheckAppNoMaterialSwitchListTile(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test(
      'allowlists Ct-* catalog widgets under features/game/widgets/chrome/',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_switchlisttile_chrome_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => SwitchListTile(
  title: const Text('x'),
  value: false,
  onChanged: (_) {},
);
''');

        final code = runCheckAppNoMaterialSwitchListTile(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists dev-tooling screens (SYS10001, SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_switchlisttile_devtools_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const debugConsole =
          'app/lib/features/game/flame/debug_console_overlay_panel.dart';
      const debugViewer =
          'app/lib/features/debug_log/debug_log_viewer_screen.dart';

      for (final rel in [debugConsole, debugViewer]) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget bypass() => SwitchListTile(
  title: const Text('x'),
  value: false,
  onChanged: (_) {},
);
''');
      }

      final code = runCheckAppNoMaterialSwitchListTile(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test(
      'does not scan test files inside features/ (production surface only)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_switchlisttile_test_skip_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/some_widget_test.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget probe() => SwitchListTile(
  title: const Text('x'),
  value: false,
  onChanged: (_) {},
);
''');

        final code = runCheckAppNoMaterialSwitchListTile(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_switchlisttile_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialSwitchListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_switchlisttile_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'Widget z() => SwitchListTile(title: const Text(\'x\'), value: false, onChanged: (_) {});\n',
        );

      final logs = <String>[];
      final code = runCheckAppNoMaterialSwitchListTile(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: SwitchListTile('),
      );
    });
  });

  group('shouldSkipAppNoMaterialSwitchListTileFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/x/y.g.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/x/y.freezed.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/x/y.mocks.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/x/y.gen.dart',
        ),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/x/y_test.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/x/test/y.dart',
        ),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/game/widgets/chrome/ct_thing.dart',
        ),
        isTrue,
      );
    });

    test('skips canonical dev-tooling screens', () {
      const skipped = <String>[
        'app/lib/features/debug_log/debug_log_viewer_screen.dart',
        'app/lib/features/game/flame/debug_console_overlay_panel.dart',
      ];
      for (final path in skipped) {
        expect(
          shouldSkipAppNoMaterialSwitchListTileFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test('does not skip ordinary feature widgets (in scope for the check)', () {
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/game/widgets/game_map_options_dialog.dart',
        ),
        isFalse,
      );
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/game/widgets/move_fleet_dialog.dart',
        ),
        isFalse,
      );
      expect(
        shouldSkipAppNoMaterialSwitchListTileFile(
          'app/lib/features/game/flame/game_screen.dart',
        ),
        isFalse,
      );
    });
  });

  group('bannedSwitchListTileConstructionPattern (regex shape)', () {
    test(
      'matches SwitchListTile + adaptive constructor with opening paren',
      () {
        const samples = <String>[
          'SwitchListTile(',
          'SwitchListTile (',
          'SwitchListTile.adaptive(',
        ];
        for (final s in samples) {
          expect(
            bannedSwitchListTileConstructionPattern.hasMatch('foo $s bar'),
            isTrue,
            reason: 'expected pattern to match $s',
          );
        }
      },
    );

    test('does not match identifiers without an opening paren', () {
      const safe = <String>[
        'SwitchListTileProbe',
        'FakeSwitchListTile',
        'SwitchListTileTheme',
        'CtToggleSwitch',
        'CtSectionLabel',
        'MySwitchListTile',
        'SwitchListTile.styleFrom',
      ];
      for (final s in safe) {
        expect(
          bannedSwitchListTileConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
