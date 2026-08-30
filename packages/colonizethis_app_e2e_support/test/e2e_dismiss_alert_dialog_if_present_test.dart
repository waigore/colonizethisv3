/// Pins [e2eDismissAlertDialogIfPresent] widget-tree contract
/// (`e2e_test_shared_dismiss_alert_dialog.dart`).
///
/// Guards: label priority (`Close`→`OK`→`Cancel`→`Yes`), hit-testable
/// filter, `handlePopRoute` fallback, and `dismiss_alert_dialog_calls`
/// counter (bumped on success only). Refs GitHub #2336 AC1 / AC2 / AC10.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/dismiss_alert_dialog_counter_group.dart';
import 'support/dismiss_alert_dialog_perf_attribution_group.dart';
import 'support/dismiss_widget_tester_harness.dart';
import 'support/e2e_dismiss_alert_dialog_if_present_guard_group.dart';

void main() {
  suppressLogsForTests();

  group('e2eDismissAlertDialogIfPresent — constant pins', () {
    test('kE2eDefaultAlertDialogDismissTimeout matches legacy 2 s budget', () {
      // The legacy inline AlertDialog branch of e2eDismissTransientUi used a
      // hardcoded 2 s timeout. A silent drift here would either inflate the
      // per-call dismiss window (regressing AC9 aggregate wall-clock) or
      // shrink it (risking false negatives when the dialog dismiss
      // animation runs slow under load).
      expect(
        kE2eDefaultAlertDialogDismissTimeout,
        const Duration(seconds: 2),
        reason:
            'kE2eDefaultAlertDialogDismissTimeout must preserve the legacy 2 s '
            'inline budget to keep AC9 aggregate wall-clock attribution '
            'stable across the lift.',
      );
    });

    test('kE2eDefaultAlertDialogDismissLabels priority is Close > OK > '
        'Cancel > Yes', () {
      // Pre-lift literal order in `e2eDismissTransientUi`. Reordering would
      // silently change which button gets tapped when more than one label
      // is hit-testable (e.g. dialog with both `Close` and `OK` actions
      // should prefer `Close` to avoid accidentally confirming a default).
      expect(
        kE2eDefaultAlertDialogDismissLabels,
        const <String>['Close', 'OK', 'Cancel', 'Yes'],
        reason:
            'kE2eDefaultAlertDialogDismissLabels priority must remain '
            '[Close, OK, Cancel, Yes] to preserve the legacy dismissal '
            'precedence.',
      );
    });
  });

  group('e2eDismissAlertDialogIfPresent — no-AlertDialog branch', () {
    testWidgets(
      'returns false without tapping or popping when no AlertDialog is mounted',
      (WidgetTester tester) async {
        var siblingTaps = 0;
        await tester.pumpWidget(
          wrapDismissCentered(
            TextButton(
              onPressed: () => siblingTaps++,
              child: const Text('Close'),
            ),
          ),
        );

        final dismissed = await e2eDismissAlertDialogIfPresent(tester);

        expect(
          dismissed,
          isFalse,
          reason:
              'Helper must short-circuit and return false when no AlertDialog '
              'is mounted; otherwise a stray `Close` TextButton elsewhere in '
              'the tree would be tapped between phases.',
        );
        expect(
          siblingTaps,
          0,
          reason:
              'No tap should fire when the AlertDialog branch short-circuits.',
        );
      },
    );
  });

  group('e2eDismissAlertDialogIfPresent — labelled-button priority', () {
    testWidgets('taps Close first when both Close and OK are hit-testable', (
      WidgetTester tester,
    ) async {
      final tapCounts = <String, int>{};
      await pumpDismissPostFrameAlertDialog(
        tester,
        (context) => labelledActionAlertDialog(
          title: 'priority-pin',
          labels: const ['OK', 'Close'],
          tapCounts: tapCounts,
        ),
      );
      expect(find.byType(AlertDialog), findsOneWidget);

      final dismissed = await e2eDismissAlertDialogIfPresent(tester);
      await pumpDismissPostTapSettle(tester);

      expect(
        dismissed,
        isTrue,
        reason:
            'Helper must return true after dismissing a labelled '
            'AlertDialog.',
      );
      expect(
        tapCounts['Close'],
        1,
        reason:
            'Close must be tapped first when both Close and OK are '
            'hit-testable — a reorder would silently confirm OK and the '
            'dismiss would still succeed but with the wrong action '
            'semantic.',
      );
      expect(tapCounts['OK'] ?? 0, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'taps OK when Close is absent and OK + Cancel are hit-testable',
      (WidgetTester tester) async {
        final tapCounts = <String, int>{};
        await pumpDismissPostFrameAlertDialog(
          tester,
          (context) => labelledActionAlertDialog(
            title: 'ok-priority-pin',
            labels: const ['Cancel', 'OK'],
            tapCounts: tapCounts,
          ),
        );

        final dismissed = await e2eDismissAlertDialogIfPresent(tester);
        await pumpDismissPostTapSettle(tester);

        expect(dismissed, isTrue);
        expect(
          tapCounts['OK'],
          1,
          reason:
              'OK must take precedence over Cancel when Close is absent — '
              'a reorder that put Cancel first would silently dismiss '
              'via the wrong action.',
        );
        expect(tapCounts['Cancel'] ?? 0, 0);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('taps Yes when only Yes is present (last-priority label)', (
      WidgetTester tester,
    ) async {
      final tapCounts = <String, int>{};
      await pumpDismissPostFrameAlertDialog(
        tester,
        (context) => labelledActionAlertDialog(
          title: 'yes-only-pin',
          labels: const ['Yes'],
          tapCounts: tapCounts,
        ),
      );

      final dismissed = await e2eDismissAlertDialogIfPresent(tester);
      await pumpDismissPostTapSettle(tester);

      expect(dismissed, isTrue);
      expect(tapCounts['Yes'], 1);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('e2eDismissAlertDialogIfPresent — hit-testable filter contract', () {
    testWidgets('taps a later labelled match when the higher-priority label is '
        'covered (non-hit-testable)', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapDismissMaterial(
          DismissPostFrameDialogHost(
            dialogBuilder: (context) => coveredFirstActionAlertDialog(
              firstLabel: 'Close',
              secondLabel: 'OK',
            ),
          ),
        ),
      );
      await pumpDismissOverlaySettle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Close'),
        findsOneWidget,
        reason:
            'Fixture must keep the Close action mounted (covered by an '
            'opaque overlay) so the hit-testable filter has a non-trivial '
            'choice to make.',
      );
      expect(find.text('OK'), findsOneWidget);

      // A regression that drops `.hitTestable()` would resolve `Close`
      // to the covered first action, tap it, and the dismiss would
      // miss — the AlertDialog would remain mounted and the loop
      // moves to `OK`. The lifted form filters `Close` to zero hit-
      // testable matches up-front, falls through, and finds the
      // hit-testable `OK` button on the next iteration.
      final dismissed = await e2eDismissAlertDialogIfPresent(tester);
      await pumpDismissPostTapSettle(tester);

      expect(
        dismissed,
        isTrue,
        reason:
            'Helper must return true even when the higher-priority Close '
            'is non-hit-testable, by tapping the hit-testable OK fallback.',
      );
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason:
            'The hit-testable OK must dismiss the AlertDialog; if this '
            'fails the helper has regressed past the hit-testable filter '
            'and is tapping the covered, non-hit-testable Close.',
      );
    });
  });

  registerDismissAlertDialogCounterGroup();
  registerDismissAlertDialogPerfAttributionGroup();
  registerE2eDismissAlertDialogIfPresentGuardGroup();
}
