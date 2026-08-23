// Guard: TrainDialogInlineCost is the only inline cost widget (Refs #4606 Slice D).
// SPEC: SPEC/ui/components/train-dialog-chrome.md. Host: train_dialog_inline_cost_tooltip_test.dart.
import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('_InlineCost de-duplication guard', () {
    test('the private _InlineCost class lives nowhere — the shared '
        'TrainDialogInlineCost is the single source', () {
      final String military = File(
        'lib/features/game/widgets/train/train_military_dialog.dart',
      ).readAsStringSync();
      final String naval = File(
        'lib/features/game/widgets/train/train_naval_dialog.dart',
      ).readAsStringSync();
      final String chrome = File(
        'lib/features/game/widgets/train/train_dialog_chrome.dart',
      ).readAsStringSync();
      final String chromeUnitRowCost = File(
        'lib/features/game/widgets/train/train_dialog_chrome_unit_row_cost.dart',
      ).readAsStringSync();
      // Refs #3686: the military/naval cost rows (incl. the inline cost
      // segments) are now rendered by the shared commodity-cost base, so the
      // single `TrainDialogInlineCost` reference lives there rather than in
      // each thin dialog file.
      final String commodityCostBase = File(
        'lib/features/game/widgets/train/train_commodity_cost_dialog_base.dart',
      ).readAsStringSync();
      final String commodityCostUnitRow = File(
        'lib/features/game/widgets/train/train_commodity_cost_dialog_base_unit_row.dart',
      ).readAsStringSync();

      expect(
        military.contains('class _InlineCost'),
        isFalse,
        reason: 'train_military_dialog.dart must not redeclare _InlineCost.',
      );
      expect(
        naval.contains('class _InlineCost'),
        isFalse,
        reason: 'train_naval_dialog.dart must not redeclare _InlineCost.',
      );
      expect(
        commodityCostBase.contains('class _InlineCost'),
        isFalse,
        reason:
            'train_commodity_cost_dialog_base.dart must not redeclare '
            '_InlineCost.',
      );
      expect(
        chrome.contains('class TrainDialogInlineCost') ||
            chromeUnitRowCost.contains('class TrainDialogInlineCost'),
        isTrue,
        reason:
            'TrainDialogInlineCost must be the single shared cost segment in '
            'train_dialog_chrome.dart (or its unit-row library files).',
      );
      expect(
        commodityCostBase.contains('TrainDialogInlineCost') ||
            commodityCostUnitRow.contains('TrainDialogInlineCost'),
        isTrue,
      );
    });
  });
}
