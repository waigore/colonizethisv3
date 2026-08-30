/// Pins the dialog-scoped `RadioListTile<…>` lookup contract of
/// [e2eRadioListTilesInAlertDialogs] (`app/integration_test/e2e_test_shared.dart`).
///
/// The fleet-reach move helper (`e2ePickMoveDestinationAndConfirm` in
/// `e2e_test_shared_panels.dart`) taps
/// `e2eRadioListTilesInAlertDialogs().first` to pick the destination sea
/// radio when no warp row is present. Two regressions would silently
/// re-introduce flakes / stalls if the helper drifted:
///
///   1. **Dropping the `find.byType(AlertDialog)` scope** would match
///      `RadioListTile`s outside the dialog — the unit/civilian/production
///      panel trees host their own radios for filters and settings, so an
///      unscoped finder can return a tile that lives in a side panel and
///      never advance the move dialog. The fleet-reach loop would stall
///      until the 35-tap cap (`_kMaxNextTurnTapsForNwFleetReach`) instead
///      of completing at the first qualifying sea radio.
///   2. **Binding the matcher to a concrete `RadioListTile<String>`**
///      would silently miss every future move dialog parameterised on a
///      different type (a destination enum, a province id record, etc.).
///      The current `runtimeType.toString().startsWith('RadioListTile<')`
///      contract matches **every** generic instantiation, which keeps the
///      helper resilient to type-argument changes in
///      `naval_tree_builder.dart` / move-fleet dialog widgets.
///
/// The integration suite cannot validate this directly (the
/// `app_e2e_linux` lane is a no-op per `SPEC/program/e2e-integration-tests.md`
/// § CI), so the widget-test layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2.
library;

// The production move-fleet dialog (`move_fleet_dialog.dart`) constructs
// `RadioListTile<_MovePick>` with the legacy `groupValue` / `onChanged`
// API; the AC1 helper matches on `runtimeType.toString()`, so the test
// fixtures must build the same widget shape (not the newer RadioGroup-
// based API) for the pin to validate the production code path.
// ignore_for_file: deprecated_member_use

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/e2e_alert_dialog_pump_harness.dart';
import 'support/e2e_widget_pump_harness.dart';
import 'support/e2e_radio_list_tiles_in_alert_dialogs_guard_group.dart';
import 'support/e2e_radio_list_tiles_in_alert_dialogs_true_group.dart';

void main() {
  suppressLogsForTests();

  group('e2eRadioListTilesInAlertDialogs — false / empty branches', () {
    testWidgets('no AlertDialog mounted -> findsNothing', (tester) async {
      await tester.pumpWidget(wrapE2eScaffold(const SizedBox()));
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'Without an AlertDialog in the tree the descendant lookup must '
            'short-circuit to zero matches. A regression that dropped the '
            '`of: find.byType(AlertDialog)` scope would match nothing here '
            'too (no radios at all), so this test must be paired with the '
            '"radio outside dialog ignored" branch below to catch the '
            'scope-drop regression on its own.',
      );
    });

    testWidgets('AlertDialog with no RadioListTile -> findsNothing', (
      tester,
    ) async {
      await pumpE2eAlertDialog(
        tester,
        dialogChildren: const [Text('Pick a destination')],
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'AlertDialog content that holds only Text (the move dialog '
            'fall-back when no legal sea step exists) must keep the helper '
            'empty. A wrapper that matched any descendant — or that '
            'misread the AlertDialog body as a RadioListTile parent — '
            'would surface false positives here.',
      );
    });

    testWidgets('RadioListTile outside any AlertDialog -> findsNothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapE2eScaffold(
          RadioListTile<String>(
            title: const Text('panel-side'),
            value: 'a',
            groupValue: 'b',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        e2eRadioListTilesInAlertDialogs(),
        findsNothing,
        reason:
            'A panel-side RadioListTile (settings sheet, civilian panel '
            'filter, etc.) must NOT leak into the dialog-scoped lookup. '
            'Dropping the `find.byType(AlertDialog)` scope would match '
            'this tile and let the fleet-reach move helper tap the wrong '
            'control, stalling the loop at the 35-tap cap.',
      );
    });

    testWidgets(
      'AlertDialog without RadioListTile + RadioListTile outside dialog -> findsNothing',
      (tester) async {
        await pumpE2eAlertDialog(
          tester,
          dialogChildren: const [Text('Confirm warp?')],
          outsideDialog: [
            RadioListTile<int>(
              title: const Text('outside'),
              value: 1,
              groupValue: 2,
              onChanged: (_) {},
            ),
          ],
        );
        expect(
          e2eRadioListTilesInAlertDialogs(),
          findsNothing,
          reason:
              'Composite of the previous two branches: even with a '
              'mounted AlertDialog the lookup must remain empty when the '
              'only RadioListTile lives outside the dialog. A regression '
              'that swapped the descendant scope for an ancestor scope '
              '(or dropped it entirely) would match the panel-side tile.',
        );
      },
    );
  });

  registerE2eRadioListTilesInAlertDialogsTrueGroup();

  registerE2eRadioListTilesInAlertDialogsGuardGroup();
}
