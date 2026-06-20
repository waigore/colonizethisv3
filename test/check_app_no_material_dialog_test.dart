import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_no_material_dialog.dart';

void main() {
  group('runCheckAppNoMaterialDialog', () {
    test(
      'passes when feature files use CtDialogShell (no Material Dialog)',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_dialog_pass_',
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
    return const CtDialogShell(child: Text('body'));
  }
}
''');

        final logs = <String>[];
        final code = runCheckAppNoMaterialDialog(
          temp.path,
          info: logs.add,
          err: logs.add,
        );

        expect(code, 0);
        expect(logs.join('\n'), contains('no violations found'));
      },
    );

    test('fails when a feature file constructs Dialog(', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dialog_bad_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/bad_dialog.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget popup() => Dialog(
  child: const Text('body'),
);
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialDialog(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('bad_dialog.dart:3: Dialog('));
      expect(logs.join('\n'), contains('CtDialogShell'));
    });

    test('fails on the Dialog.fullscreen named constructor', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dialog_named_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/named.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget a() => Dialog.fullscreen(child: const Text('a'));
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialDialog(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('Dialog.fullscreen('));
    });

    test('passes when Dialog appears inside a // comment or /// dartdoc', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dialog_comment_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File('${temp.path}/app/lib/features/game/widgets/ok_comment.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter/material.dart';

/// Prefer CtDialogShell over Dialog( for popups.
// Dialog( must not appear in real code, but a // comment is fine.
class C {}
''');

      final logs = <String>[];
      final code = runCheckAppNoMaterialDialog(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0);
      expect(logs.join('\n'), contains('no violations found'));
    });

    test(
      'does not flag AlertDialog / SimpleDialog / showDialog / sibling types',
      () {
        final temp = Directory.systemTemp.createTempSync(
          'check_app_no_material_dialog_siblings_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));

        File('${temp.path}/app/lib/features/game/widgets/siblings.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';

void open(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const CtDialogShell(child: Text('x')));
  showGeneralDialog<void>(context: context, pageBuilder: (_, __, ___) => const Text('x'));
}
Widget a() => SimpleDialog(children: const [Text('a')]);
DialogRoute<void> r() => DialogRoute<void>(context: _ctx, builder: (_) => const Text('x'));
ThemeData t() => ThemeData(dialogTheme: const DialogTheme());
final BuildContext _ctx = throw UnimplementedError();
''');

        final code = runCheckAppNoMaterialDialog(
          temp.path,
          info: (_) {},
          err: (_) {},
        );

        expect(code, 0);
      },
    );

    test('allowlists Ct-* chrome widgets and dev-tooling screens', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dialog_allow_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      const allowed = <String>[
        'app/lib/features/game/widgets/chrome/ct_dialog_shell.dart',
        'app/lib/features/debug_log/debug_log_viewer_screen.dart',
        'app/lib/features/game/flame/debug_console_overlay_panel.dart',
      ];
      for (final rel in allowed) {
        File('${temp.path}/$rel')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:flutter/material.dart';

Widget bypass() => Dialog(child: const Text('x'));
''');
      }

      final code = runCheckAppNoMaterialDialog(
        temp.path,
        info: (_) {},
        err: (_) {},
      );

      expect(code, 0);
    });

    test('returns exit 1 when app/lib/features does not exist', () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_no_material_dialog_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final logs = <String>[];
      final code = runCheckAppNoMaterialDialog(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('app/lib/features not found'));
    });
  });

  group('bannedDialogConstructionPattern (regex shape)', () {
    test('matches Dialog( and Dialog.fullscreen(', () {
      const samples = <String>['Dialog(', 'Dialog (', 'Dialog.fullscreen('];
      for (final s in samples) {
        expect(
          bannedDialogConstructionPattern.hasMatch('foo $s bar'),
          isTrue,
          reason: 'expected pattern to match $s',
        );
      }
    });

    test('does NOT match sibling dialog identifiers/types', () {
      const safe = <String>[
        'AlertDialog(',
        'SimpleDialog(',
        'showDialog(',
        'showGeneralDialog(',
        'CtDialogShell(',
        'DialogRoute(',
        'DialogTheme(',
        'Dialog',
      ];
      for (final s in safe) {
        expect(
          bannedDialogConstructionPattern.hasMatch(s),
          isFalse,
          reason: 'expected pattern NOT to match $s',
        );
      }
    });
  });
}
