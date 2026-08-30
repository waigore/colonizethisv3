/// Pins the widget-tree contract of [e2eAttemptFirstFleetMoveOrCancel]
/// (`app/integration_test/e2e_test_shared_first_fleet_move.dart`).
///
/// The full-turn E2E scenario in `new_game_full_turn_e2e_test.dart` calls
/// this helper exactly once per `testWidgets` after [e2eSplitHomeFleetOnce]
/// to opportunistically nudge any visible Move-capable fleet in the naval
/// panel, tolerating an empty destination-radios dialog by tapping Cancel.
/// A silent rename or behavioural drift here would either:
///
///   - Stall the test for `kE2eDefaultFirstFleetMoveDialogCloseTimeout` (10 s)
///     at `pump_until_move_dialog_closed*` if Confirm / Cancel never tap;
///   - Or mask an empty-radios regression by silently failing the
///     `find.text(common_cancel)` expectation — breaking the AC4 / AC5
///     adaptive-poll contract issue #2336 is enforcing.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 2.
library;

// Test fixtures build the legacy `RadioListTile<int>(groupValue, onChanged)`
// shape on purpose so the helper's exact-type
// `find.byType(RadioListTile<dynamic>)` finder can drive the confirmed /
// cancelled branches in isolation. The production `MoveFleetDialog` renders
// as a `CtDialogShell` with custom `_MoveFleetDestinationRow` rows (no
// `RadioListTile`), which is why these fixtures wrap their content in a
// `CtDialogShell` to match the dialog type the helper now waits for. Mirrors
// the deprecation suppression in
// `e2e_pick_move_destination_and_confirm_test.dart`.
// ignore_for_file: deprecated_member_use

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/attempt_fleet_move_harness.dart';
import 'support/naval_fleet_move_harness.dart';
import 'support/e2e_attempt_first_fleet_move_or_cancel_guard_group.dart';
import 'support/e2e_attempt_first_fleet_move_or_cancel_guard_group2.dart';
import 'support/e2e_attempt_first_fleet_move_or_cancel_guard_group3.dart';

void main() {
  suppressLogsForTests();

  group('e2eAttemptFirstFleetMoveOrCancel — no Move button branch', () {
    testWidgets('returns noMoveButton without opening a dialog', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(children: const [Text('Empty fleets list')]),
        ),
      );

      final outcome = await e2eAttemptFirstFleetMoveOrCancel(tester, l10n);

      expect(
        outcome,
        E2eFirstFleetMoveOutcome.noMoveButton,
        reason:
            'Helper must short-circuit without tapping or opening a dialog '
            'when no Move text descends from the naval panel root.',
      );
      expect(find.byType(CtDialogShell), findsNothing);
    });

    testWidgets('emits perf timing with result=no_move_button', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('no_move_button_perf');
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(children: const [Text('Empty fleets list')]),
        ),
      );

      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await e2eAttemptFirstFleetMoveOrCancel(tester, l10n, perf: perf);
      } finally {
        debugPrint = original;
      }

      expect(
        lines.any(
          (l) =>
              l.contains('attempt_first_fleet_move') &&
              l.contains('result=no_move_button'),
        ),
        isTrue,
        reason:
            'perf wiring must emit the no_move_button marker so wall-clock '
            'attribution sees the short-circuit branch fired.',
      );
    });
  });

  group('e2eAttemptFirstFleetMoveOrCancel — cancel-on-empty-radios branch', () {
    testWidgets('taps Cancel and returns cancelled when no radios present', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              FleetMoveButton(
                buttonKey: kCtE2EFleetMoveActionKey,
                dialogBuilder: emptyRadiosDialogBuilder(l10n),
              ),
            ],
          ),
        ),
      );

      final outcome = await e2eAttemptFirstFleetMoveOrCancel(tester, l10n);

      expect(
        outcome,
        E2eFirstFleetMoveOutcome.cancelled,
        reason:
            'Empty destination-radios dialog must dismiss via Cancel, not '
            'via Confirm. A regression that picked the first radio would '
            'commit an invalid move and stall the dialog-close pump.',
      );
      expect(find.byType(CtDialogShell), findsNothing);
    });

    testWidgets('emits perf timing with result=cancelled', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('cancelled_perf');
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              FleetMoveButton(
                buttonKey: kCtE2EFleetMoveActionKey,
                dialogBuilder: emptyRadiosDialogBuilder(l10n),
              ),
            ],
          ),
        ),
      );

      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await e2eAttemptFirstFleetMoveOrCancel(tester, l10n, perf: perf);
      } finally {
        debugPrint = original;
      }

      expect(
        lines.any(
          (l) =>
              l.contains('attempt_first_fleet_move') &&
              l.contains('result=cancelled'),
        ),
        isTrue,
      );
    });
  });

  registerE2eAttemptFirstFleetMoveOrCancelGuardGroup();

  registerE2eAttemptFirstFleetMoveOrCancelGuardGroup2();

  registerE2eAttemptFirstFleetMoveOrCancelGuardGroup3();
}
