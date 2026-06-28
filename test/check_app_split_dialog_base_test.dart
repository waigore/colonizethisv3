// Refs #3594 — guards `repo.split_dialog_base` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_split_dialog_base.dart';

void main() {
  group('repo.split_dialog_base', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAppSplitDialogBase(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_app_split_dialog_base: all `Split*Dialog` widgets extend '
          'SplitEntityDialog.',
        ),
      );
    });

    test('fails when a Split*Dialog omits `extends SplitEntityDialog`', () {
      final temp = Directory.systemTemp.createTempSync('split_dialog_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'split_garrison_dialog.dart'))
          .writeAsStringSync(
            'class SplitGarrisonDialog extends StatelessWidget {\n'
            '  const SplitGarrisonDialog({super.key});\n'
            '}\n',
          );

      final errLogs = <String>[];
      final code = runCheckAppSplitDialogBase(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('split_garrison_dialog.dart'));
      expect(errLogs.join('\n'), contains('SplitGarrisonDialog'));
      expect(errLogs.join('\n'), contains('SplitEntityDialog'));
    });

    test('passes when a Split*Dialog adopts `extends SplitEntityDialog`', () {
      final temp = Directory.systemTemp.createTempSync('split_dialog_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'split_garrison_dialog.dart'))
          .writeAsStringSync(
            'class SplitGarrisonDialog extends SplitEntityDialog {\n'
            '  const SplitGarrisonDialog({super.key});\n'
            '}\n',
          );

      final code = runCheckAppSplitDialogBase(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts the SplitEntityDialog base itself', () {
      final temp = Directory.systemTemp.createTempSync('split_dialog_base_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'split_entity_dialog.dart'))
          .writeAsStringSync(
            'abstract class SplitEntityDialog extends StatelessWidget {\n'
            '  const SplitEntityDialog({super.key});\n'
            '}\n',
          );

      final code = runCheckAppSplitDialogBase(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts private _Split*Dialog helpers', () {
      final temp = Directory.systemTemp.createTempSync('split_dialog_priv_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'split_helper.dart')).writeAsStringSync(
        'class _SplitRowDialog extends StatelessWidget {\n'
        '  const _SplitRowDialog();\n'
        '}\n',
      );

      final code = runCheckAppSplitDialogBase(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}
