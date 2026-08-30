// Extracted from e2e_radio_list_tiles_in_alert_dialogs_test.dart (#4598).
library;

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'e2e_alert_dialog_pump_harness.dart';

void registerE2eRadioListTilesInAlertDialogsTrueGroup() {
  group('e2eRadioListTilesInAlertDialogs — true branches', () {
    testWidgets('single RadioListTile<String> inside AlertDialog -> 1 match', (
      tester,
    ) async {
      await pumpE2eAlertDialog(
        tester,
        dialogChildren: [
          RadioListTile<String>(
            title: const Text('sea1'),
            value: 'sea1',
            groupValue: '',
            onChanged: (_) {},
          ),
        ],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsOneWidget,
        reason:
            'The canonical fleet-reach move dialog parameterises '
            'destination tiles on `RadioListTile<String>` (the sea-zone '
            'id). A single radio must surface as exactly one match — the '
            'fleet helper calls `.first` on it, so any over-count would '
            'still pass but any under-count (matcher too strict) would '
            'fail this assertion.',
      );
    });

    testWidgets('multiple RadioListTile<String> inside AlertDialog -> N', (
      tester,
    ) async {
      await pumpE2eAlertDialog(
        tester,
        dialogChildren: [
          for (final id in const ['sea1', 'sea2', 'sea3'])
            RadioListTile<String>(
              title: Text(id),
              value: id,
              groupValue: '',
              onChanged: (_) {},
            ),
        ],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNWidgets(3),
        reason:
            'Move dialogs with multiple legal destinations must surface '
            'every radio (the helper later disambiguates via `.first`). '
            'A regression that short-circuited after the first match — '
            'or that filtered to a single index — would break multi-'
            'destination probing.',
      );
    });

    testWidgets(
      'RadioListTile with non-String type argument is still matched',
      (tester) async {
        await pumpE2eAlertDialog(
          tester,
          dialogChildren: [
            RadioListTile<int>(
              title: const Text('int-typed'),
              value: 1,
              groupValue: 2,
              onChanged: (_) {},
            ),
          ],
        );
        expect(
          e2eRadioListTilesInAlertDialogs(),
          findsOneWidget,
          reason:
              'The contract uses `runtimeType.toString().startsWith('
              '`'
              'RadioListTile<'
              '`'
              ')` so any generic instantiation (`RadioListTile<int>`, '
              '`RadioListTile<MyEnum>`, etc.) is in scope. Hard-binding '
              'the matcher to `RadioListTile<String>` would silently miss '
              'future move dialogs that parameterise on a different '
              'destination type.',
        );
      },
    );

    testWidgets(
      'RadioListTiles inside AlertDialog co-exist with siblings outside',
      (tester) async {
        await pumpE2eAlertDialog(
          tester,
          dialogChildren: [
            RadioListTile<String>(
              title: const Text('inside-1'),
              value: 'a',
              groupValue: 'b',
              onChanged: (_) {},
            ),
            RadioListTile<String>(
              title: const Text('inside-2'),
              value: 'b',
              groupValue: 'b',
              onChanged: (_) {},
            ),
          ],
          outsideDialog: [
            RadioListTile<String>(
              title: const Text('outside-1'),
              value: 'x',
              groupValue: 'y',
              onChanged: (_) {},
            ),
          ],
        );
        expect(
          e2eRadioListTilesInAlertDialogs(),
          findsNWidgets(2),
          reason:
              'The dialog-scoped lookup must count exactly the two '
              'in-dialog tiles, never the outside sibling. This is the '
              'canonical "panel + dialog co-mounted" regression guard for '
              'move-dialog tapping (Bottleneck 4 of #2336).',
        );
      },
    );
  });
}
