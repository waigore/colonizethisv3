// Refs #3686 — guards `repo.app_train_dialog_commodity_cost_shared`.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_train_dialog_commodity_cost_dedup.dart';

const _militaryRelative =
    'app/lib/features/game/widgets/train_military_dialog.dart';
const _navalRelative = 'app/lib/features/game/widgets/train_naval_dialog.dart';

File _targetFile(String root, String relative) {
  final file = File(p.join(root, relative));
  file.parent.createSync(recursive: true);
  return file;
}

/// A minimal, compliant commodity-cost dialog pair (extends the base, no
/// duplicated machinery) so the fail-case temp trees only differ by the
/// violation under test.
void _writeCompliantPair(String root) {
  _targetFile(root, _militaryRelative).writeAsStringSync(
    'class _TrainMilitaryDialogState\n'
    '    extends CommodityCostTrainDialogState<TrainMilitaryDialog> {}\n',
  );
  _targetFile(root, _navalRelative).writeAsStringSync(
    'class _TrainNavalDialogState\n'
    '    extends CommodityCostTrainDialogState<TrainNavalDialog> {}\n',
  );
}

void main() {
  group('repo.app_train_dialog_commodity_cost_shared', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAppTrainDialogCommodityCostDedup(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'the commodity-cost train dialogs extend '
          'CommodityCostTrainDialogState',
        ),
      );
    });

    test('passes when both dialogs extend the base with no cost machinery', () {
      final temp = Directory.systemTemp.createTempSync('cc_dialog_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeCompliantPair(temp.path);

      final code = runCheckAppTrainDialogCommodityCostDedup(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('fails when a dialog omits `extends CommodityCostTrainDialogState`', () {
      final temp = Directory.systemTemp.createTempSync('cc_dialog_noext_');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeCompliantPair(temp.path);
      // Naval drops the canonical base.
      _targetFile(temp.path, _navalRelative).writeAsStringSync(
        'class _TrainNavalDialogState extends TrainDialogBaseState {}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAppTrainDialogCommodityCostDedup(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains('train_naval_dialog.dart'));
      expect(errLogs.join('\n'), contains('CommodityCostTrainDialogState'));
    });

    test('fails when a dialog re-declares commodity-cost cost math', () {
      final temp = Directory.systemTemp.createTempSync('cc_dialog_math_');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeCompliantPair(temp.path);
      _targetFile(temp.path, _militaryRelative).writeAsStringSync(
        'class _TrainMilitaryDialogState\n'
        '    extends CommodityCostTrainDialogState<TrainMilitaryDialog> {\n'
        '  int _totalTreasuryCost() => 0;\n'
        '  @override\n'
        '  bool canAffordIncrement(String unitType) => false;\n'
        '}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAppTrainDialogCommodityCostDedup(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains('_totalTreasuryCost'));
      expect(errLogs.join('\n'), contains('canAffordIncrement'));
    });

    test('fails when a dialog re-declares a private resource-bar / row widget', () {
      final temp = Directory.systemTemp.createTempSync('cc_dialog_widget_');
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeCompliantPair(temp.path);
      _targetFile(temp.path, _navalRelative).writeAsStringSync(
        'class _TrainNavalDialogState\n'
        '    extends CommodityCostTrainDialogState<TrainNavalDialog> {}\n'
        'class _NavalResourceBar extends StatelessWidget {}\n'
        'class _ShipTypeRow extends StatelessWidget {}\n',
      );

      final errLogs = <String>[];
      final code = runCheckAppTrainDialogCommodityCostDedup(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains('_NavalResourceBar'));
      expect(errLogs.join('\n'), contains('_ShipTypeRow'));
    });
  });
}
