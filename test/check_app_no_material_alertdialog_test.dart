import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_alertdialog.dart';

void main() {
  group('runCheckAppNoMaterialAlertDialog', () {
    test(
      'passes when every features file uses CtDialogShell (no AlertDialog)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_alertdialog_pass_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/clean.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';

class Clean extends StatelessWidget {
  const Clean({super.key});

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      child: const SizedBox.shrink(),
    );
  }
}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialAlertDialog(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('fails when a feature file constructs AlertDialog(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_alertdialog_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_confirm.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget confirm() => AlertDialog(
  title: const Text('Confirm'),
  actions: const [],
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialAlertDialog(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('bad_confirm.dart:3: AlertDialog('),
      );
      expect(
        logs.join('\n'),
        contains('CtDialogShell'),
      );
    });

    test('fails for AlertDialog.adaptive variant', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_alertdialog_adaptive_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/adaptive.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget adaptive() => AlertDialog.adaptive(
  title: const Text('Adaptive'),
  actions: const [],
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialAlertDialog(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('AlertDialog.adaptive('),
      );
    });

    test(
      'passes when AlertDialog appears inside a // comment or /// dartdoc',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_alertdialog_comment_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtDialogShell over AlertDialog( for dialog popups.
// AlertDialog( must not appear in real code, but a // comment is fine.
class C {}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialAlertDialog(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test(
      'does not flag identifiers that contain "AlertDialog" without '
      'an opening paren (false-positive guard)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_alertdialog_identifier_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/identifier.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

class FakeAlertDialogProbe {
  static const String label = 'AlertDialogProbe';
}
''');

        final code = runCheckAppNoMaterialAlertDialog(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test(
      'allowlists Ct-* catalog widgets under features/game/widgets/chrome/',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_alertdialog_chrome_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/chrome/ct_thing.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget fallback() => AlertDialog(title: const Text('x'), actions: const []);
''');

        final code = runCheckAppNoMaterialAlertDialog(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists the Debug Console Overlay dev-tooling screen (SYS20001)', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_alertdialog_devtools_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const debugConsole =
          'app/lib/features/game/flame/debug_console_overlay_panel.dart';

      for (final rel in [debugConsole]) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget bypass() => AlertDialog(title: const Text('x'), actions: const []);
''');
      }

      final code = runCheckAppNoMaterialAlertDialog(
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
          'check_app_no_material_alertdialog_test_skip_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File(
          '${temp.path}/app/lib/features/game/widgets/some_widget_test.dart',
        )
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget probe() => AlertDialog(title: const Text('x'), actions: const []);
''');

        final code = runCheckAppNoMaterialAlertDialog(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_alertdialog_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialAlertDialog(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });

    test('reports file path and line number on violation', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_alertdialog_line_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/x/y.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'import \'package:flutter/material.dart\';\n'
          '// line 2\n'
          '// line 3\n'
          'Widget z() => AlertDialog(title: const Text(\'x\'), actions: const []);\n',
        );

      final logs = <String>[];
      final code = runCheckAppNoMaterialAlertDialog(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('app/lib/features/x/y.dart:4: AlertDialog('),
      );
    });
  });

  group('shouldSkipAppNoMaterialAlertDialogFile (scope predicate)', () {
    test('skips generated suffixes', () {
      expect(
        shouldSkipAppNoMaterialAlertDialogFile(
          'app/lib/features/x/y.g.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialAlertDialogFile(
          'app/lib/features/x/y.freezed.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialAlertDialogFile(
          'app/lib/features/x/y.mocks.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialAlertDialogFile(
          'app/lib/features/x/y.gen.dart',
        ),
        isTrue,
      );
    });

    test('skips test files inside features/', () {
      expect(
        shouldSkipAppNoMaterialAlertDialogFile(
          'app/lib/features/x/y_test.dart',
        ),
        isTrue,
      );
      expect(
        shouldSkipAppNoMaterialAlertDialogFile(
          'app/lib/features/x/test/y.dart',
        ),
        isTrue,
      );
    });

    test('skips Ct-* chrome catalog widgets', () {
      expect(
        shouldSkipAppNoMaterialAlertDialogFile(
          'app/lib/features/game/widgets/chrome/ct_thing.dart',
        ),
        isTrue,
      );
    });

    test('skips the Debug Console Overlay dev-tooling screen (SYS20001)', () {
      const skipped = <String>[
        'app/lib/features/game/flame/debug_console_overlay_panel.dart',
      ];
      for (final path in skipped) {
        expect(
          shouldSkipAppNoMaterialAlertDialogFile(path),
          isTrue,
          reason: 'expected $path to be allowlisted',
        );
      }
    });

    test(
      'does not skip ordinary feature widgets (in scope for the check)',
      () {
        expect(
          shouldSkipAppNoMaterialAlertDialogFile(
            'app/lib/features/game/widgets/move_fleet_dialog.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppNoMaterialAlertDialogFile(
            'app/lib/features/game/widgets/military_units_panel.dart',
          ),
          isFalse,
        );
        expect(
          shouldSkipAppNoMaterialAlertDialogFile(
            'app/lib/features/game/flame/game_screen.dart',
          ),
          isFalse,
        );
      },
    );
  });

  group('bannedAlertDialogConstructionPattern (regex shape)', () {
    test('matches AlertDialog + adaptive constructor with opening paren', () {
      const samples = <String>[
        'AlertDialog(',
        'AlertDialog (',
        'AlertDialog.adaptive(',
      ];
      for (final s in samples) {
        expect(
          bannedAlertDialogConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does not match identifiers without an opening paren', () {
      const safe = <String>[
        'AlertDialogProbe',
        'FakeAlertDialog',
        'AlertDialogTheme',
        'CtDialogShell',
        'CtFullScreenDialogueShell',
        'AlertDialog.styleFrom',
      ];
      for (final s in safe) {
        expect(
          bannedAlertDialogConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
