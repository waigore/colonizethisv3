// Refs #3594 — guards `repo.train_dialog_base` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_train_dialog_base.dart';

void main() {
  group('repo.train_dialog_base', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAppTrainDialogBase(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_app_train_dialog_base: all `Train*Dialog` widgets extend '
          'TrainDialogBase.',
        ),
      );
    });

    test('fails when a Train*Dialog omits `extends TrainDialogBase`', () {
      final temp = Directory.systemTemp.createTempSync('train_dialog_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'train_settlers_dialog.dart'))
          .writeAsStringSync(
            'class TrainSettlersDialog extends StatefulWidget {\n'
            '  const TrainSettlersDialog({super.key});\n'
            '}\n',
          );

      final errLogs = <String>[];
      final code = runCheckAppTrainDialogBase(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('train_settlers_dialog.dart'));
      expect(errLogs.join('\n'), contains('TrainSettlersDialog'));
      expect(errLogs.join('\n'), contains('TrainDialogBase'));
    });

    test('passes when a Train*Dialog adopts `extends TrainDialogBase`', () {
      final temp = Directory.systemTemp.createTempSync('train_dialog_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'train_settlers_dialog.dart'))
          .writeAsStringSync(
            'class TrainSettlersDialog extends TrainDialogBase {\n'
            '  const TrainSettlersDialog({super.key});\n'
            '}\n',
          );

      final code = runCheckAppTrainDialogBase(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts the TrainDialogBase base itself', () {
      final temp = Directory.systemTemp.createTempSync('train_dialog_base_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'train_dialog_base.dart'))
          .writeAsStringSync(
            'abstract class TrainDialogBase extends StatefulWidget {\n'
            '  const TrainDialogBase({super.key});\n'
            '}\n',
          );

      final code = runCheckAppTrainDialogBase(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts non-dialog Train* chrome widgets (e.g. TrainDialogHeader)', () {
      final temp = Directory.systemTemp.createTempSync('train_dialog_chrome_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'train_dialog_chrome.dart'))
          .writeAsStringSync(
            'class TrainDialogHeader extends StatelessWidget {\n'
            '  const TrainDialogHeader({super.key});\n'
            '}\n',
          );

      final code = runCheckAppTrainDialogBase(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('exempts private _Train*Dialog helpers', () {
      final temp = Directory.systemTemp.createTempSync('train_dialog_priv_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final widgetsDir = Directory(
        p.join(temp.path, 'app/lib/features/game/widgets'),
      )..createSync(recursive: true);

      File(p.join(widgetsDir.path, 'train_helper.dart')).writeAsStringSync(
        'class _TrainRowDialog extends StatelessWidget {\n'
        '  const _TrainRowDialog();\n'
        '}\n',
      );

      final code = runCheckAppTrainDialogBase(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}
