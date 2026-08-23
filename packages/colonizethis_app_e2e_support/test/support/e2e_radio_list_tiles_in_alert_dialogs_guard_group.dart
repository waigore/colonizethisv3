// Extracted from e2e_radio_list_tiles_in_alert_dialogs_test.dart (#4598 Slice C).
library;

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'e2e_alert_dialog_pump_harness.dart';
import 'e2e_widget_pump_harness.dart';

void registerE2eRadioListTilesInAlertDialogsGuardGroup() {
  group('e2eRadioListTilesInAlertDialogs — regression guards', () {
    testWidgets('plain ListTile (no Radio prefix) is rejected', (tester) async {
      await pumpE2eAlertDialog(
        tester,
        dialogChildren: const [ListTile(title: Text('plain-list-tile'))],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'A plain `ListTile` inside the dialog must NOT match the '
            'finder. The fleet-reach helper depends on tapping the '
            'RadioListTile (so the tile selection updates before '
            'Confirm); matching a plain ListTile would dispatch the tap '
            'to the wrong widget and silently miss the destination set.',
      );
    });

    testWidgets('CheckboxListTile inside the dialog is rejected', (
      tester,
    ) async {
      await pumpE2eAlertDialog(
        tester,
        dialogChildren: [
          CheckboxListTile(
            title: const Text('checkbox-list-tile'),
            value: false,
            onChanged: (_) {},
          ),
        ],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'Even though `CheckboxListTile` shares the `ListTile` family, '
            'the `runtimeType.toString().startsWith("RadioListTile<")` '
            'prefix excludes it deterministically. A regression to a '
            'substring-style match (`contains("ListTile")`) would '
            'surface this checkbox and break the move-dialog tap path.',
      );
    });

    testWidgets('successive calls return fresh, idle Finder objects', (
      tester,
    ) async {
      await pumpE2eAlertDialog(
        tester,
        dialogChildren: [
          RadioListTile<String>(
            title: const Text('only'),
            value: 'a',
            groupValue: '',
            onChanged: (_) {},
          ),
        ],
      );
      final first = e2eRadioListTilesInAlertDialogs();
      final second = e2eRadioListTilesInAlertDialogs();
      expect(
        identical(first, second),
        isFalse,
        reason:
            'The helper must construct a fresh Finder on each call (no '
            'caching). A shared/cached Finder would resolve against a '
            'stale Element tree across pump frames and silently report '
            'matches from a previous frame.',
      );
      expect(first.evaluate().length, 1);
      expect(second.evaluate().length, 1);
    });

    testWidgets('finder is lazy: constructible without a pumped tree', (
      tester,
    ) async {
      final finder = e2eRadioListTilesInAlertDialogs();
      expect(
        finder,
        isNotNull,
        reason:
            'The helper must not query the WidgetTester on construction; '
            'returning a lazy Finder keeps it safe to compose / store '
            'before pumping. A regression that resolved the Finder '
            'eagerly would throw outside an active tester binding.',
      );
      await tester.pumpWidget(wrapE2eScaffold(const SizedBox()));
      expect(finder.evaluate(), isEmpty);
    });
  });
}
