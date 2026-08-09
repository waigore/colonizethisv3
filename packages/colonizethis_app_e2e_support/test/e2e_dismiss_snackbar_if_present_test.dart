/// Pins the widget-tree contract of [e2eDismissSnackBarIfPresent]
/// (`app/integration_test/e2e_test_shared_dismiss_snackbar.dart`).
///
/// The shared broad-spectrum sweep [e2eDismissTransientUi] consumes this
/// helper for its SnackBar branch (every panel-opener pre-tap dismiss
/// across the three integration scenarios). The pre-lift inline block had
/// a subtle defect: it checked
/// `snackAction.hitTestable().evaluate().isNotEmpty` for presence but
/// tapped `snackAction.first` — the **first [TextButton]** in the SnackBar
/// **without** the hit-testable filter. A SnackBar whose first action was
/// covered by a transient overlay (rare but possible — a SnackBar plus a
/// SnackBar replaces it during animation, leaving a stale non-hit-testable
/// first TextButton in the tree briefly) would therefore record a
/// "dismiss attempted" tap that never landed, and the surrounding
/// [e2ePumpUntilFinderEmpty] would burn the full 2 s budget before
/// returning. The lift fixes this by tapping the **hit-testable filter's
/// first match** — matching the adjacent AlertDialog and CtDialogShell
/// branches of [e2eDismissTransientUi] that already use the filtered
/// finder for both the presence check and the tap.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Coverage layers:
///
///   - **No-SnackBar short-circuit**: helper returns `false` without
///     pumping or tapping when no [SnackBar] is mounted; sibling
///     [TextButton] widgets elsewhere in the tree must not be tapped.
///   - **Hit-testable action happy path**: helper taps the single
///     hit-testable action and returns `true`; the SnackBar leaves the
///     tree.
///   - **Multi-action hit-testable filter pin**: a SnackBar with two
///     [TextButton] descendants — the first non-hit-testable (covered by
///     an opaque overlay), the second hit-testable — must tap the
///     hit-testable button, **not** the first non-hit-testable one. This
///     guards against a regression that reverts the lift to
///     `snackAction.first` and starts dropping the SnackBar dismissal.
///   - **No-hit-testable-action fallback**: helper returns `false` when
///     the SnackBar has no hit-testable [TextButton] (caller is expected
///     to fall back to a broader dismissal strategy).
///   - **`perf` counter**: [E2ePerfLog] receives a single
///     `dismiss_snackbar_calls` bump only on the success path (the
///     no-shortcut and no-hit-testable branches do not bump).
///   - **`dismissTimeout` is forwarded**: setting [dismissTimeout] to
///     [Duration.zero] does not cause the helper to throw or hang
///     (proves the timeout is plumbed through [e2ePumpUntilFinderEmpty]
///     correctly; the SnackBar may not finish unmounting under a
///     zero-budget but the call still returns `true`).
///
/// Refs GitHub #2336 AC1 / AC2 / AC10.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/dismiss_snackbar_counter_group.dart';
import 'support/dismiss_snackbar_perf_attribution_group.dart';
import 'support/dismiss_widget_tester_harness.dart';

/// Builds a SnackBar that surfaces two action [TextButton]s. When
/// [coverFirstAction] is `true`, an [AbsorbPointer] overlay sits above
/// the first [TextButton] so the first button is **mounted but
/// non-hit-testable**; the second button remains hit-testable. This
/// exercises the hit-testable filter contract on a SnackBar with two
/// action [TextButton]s — exactly the regression surface the pre-lift
/// `snackAction.first` defect would expose.
SnackBar _twoActionSnackBar({required bool coverFirstAction}) {
  final firstButton = TextButton(
    onPressed: () {},
    child: const Text('first-action'),
  );
  final secondButton = TextButton(
    onPressed: () {},
    child: const Text('second-action'),
  );
  return SnackBar(
    duration: const Duration(seconds: 30),
    content: Row(
      children: [
        if (coverFirstAction)
          SizedBox(
            width: 120,
            height: 48,
            child: absorbPointerCover(child: firstButton),
          )
        else
          firstButton,
        secondButton,
      ],
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('e2eDismissSnackBarIfPresent — no-SnackBar branch', () {
    testWidgets('returns false without tapping when no SnackBar is mounted', (
      WidgetTester tester,
    ) async {
      var siblingTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => siblingTaps++,
                child: const Text('sibling-action'),
              ),
            ),
          ),
        ),
      );

      final dismissed = await e2eDismissSnackBarIfPresent(tester);

      expect(
        dismissed,
        isFalse,
        reason:
            'Helper must short-circuit and return false when no SnackBar '
            'is mounted; otherwise a stray TextButton elsewhere in the '
            'tree would be tapped between phases.',
      );
      expect(
        siblingTaps,
        0,
        reason: 'No tap should fire when the SnackBar branch short-circuits.',
      );
    });
  });

  group('e2eDismissSnackBarIfPresent — single-action happy path', () {
    testWidgets(
      'taps the hit-testable SnackBar action and returns true after dismissal',
      (WidgetTester tester) async {
        var actionTaps = 0;
        await tester.pumpWidget(
          wrapDismissMaterial(
            DismissSnackBarHost(
              snackBar: SnackBar(
                duration: const Duration(seconds: 30),
                content: const Text('snack-content'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () => actionTaps++,
                ),
              ),
            ),
          ),
        );
        await pumpDismissOverlaySettle(tester);
        expect(find.byType(SnackBar), findsOneWidget);

        final dismissed = await e2eDismissSnackBarIfPresent(tester);
        await pumpDismissPostTapSettle(tester);

        expect(
          dismissed,
          isTrue,
          reason:
              'Helper must return true after tapping the hit-testable '
              'SnackBar action so callers can short-circuit the broader '
              'dismissal sweep.',
        );
        expect(
          actionTaps,
          1,
          reason:
              'The SnackBar action must receive exactly one tap (regression '
              'guard against double-tap or missed-tap variants).',
        );
        expect(
          find.byType(SnackBar),
          findsNothing,
          reason:
              'After the action tap the SnackBar must leave the tree within '
              'the default 2 s dismiss budget.',
        );
      },
    );
  });

  group('e2eDismissSnackBarIfPresent — hit-testable filter contract', () {
    testWidgets('taps the second action when the first action is covered '
        '(non-hit-testable)', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapDismissMaterial(
          DismissSnackBarHost(
            snackBar: _twoActionSnackBar(coverFirstAction: true),
          ),
        ),
      );
      await pumpDismissOverlaySettle(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('first-action'),
        findsOneWidget,
        reason:
            'Fixture must keep the first action mounted (covered by an '
            'opaque overlay) so the hit-testable filter has a non-trivial '
            'choice to make.',
      );
      expect(find.text('second-action'), findsOneWidget);

      // Pre-lift behavior would tap `snackAction.first` (the first
      // TextButton, which is covered and non-hit-testable here); the
      // lifted form must instead tap the hit-testable filter's first
      // match (the second action). A regression that reverts to
      // `snackAction.first` would tap the covered button and the
      // SnackBar would never dismiss — the post-dismiss expectation
      // below would fail with the SnackBar still in the tree.
      final dismissed = await e2eDismissSnackBarIfPresent(tester);
      await pumpDismissPostTapSettle(tester);

      expect(
        dismissed,
        isTrue,
        reason:
            'Helper must return true even when the first TextButton is '
            'non-hit-testable, by tapping the hit-testable second action.',
      );
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason:
            'The hit-testable second action must dismiss the SnackBar; if '
            'this fails the helper has regressed to `snackAction.first` '
            'and is tapping the covered, non-hit-testable first button.',
      );
    });
  });

  group('e2eDismissSnackBarIfPresent — no-hit-testable-action branch', () {
    testWidgets(
      'returns false when the SnackBar has no hit-testable TextButton',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapDismissMaterial(
            DismissSnackBarHost(
              snackBar: const SnackBar(
                duration: Duration(seconds: 30),
                content: Text('no-action-content'),
              ),
            ),
          ),
        );
        await pumpDismissOverlaySettle(tester);
        expect(find.byType(SnackBar), findsOneWidget);

        final dismissed = await e2eDismissSnackBarIfPresent(tester);

        expect(
          dismissed,
          isFalse,
          reason:
              'Helper must return false when no hit-testable TextButton is '
              'present so callers can fall back to a broader dismissal '
              'strategy (handlePopRoute or AlertDialog/CtDialogShell '
              'sweep).',
        );
        expect(
          find.byType(SnackBar),
          findsOneWidget,
          reason:
              'The SnackBar must remain mounted when the helper returns '
              'false; a regression that tapped despite no hit-testable '
              'action would silently dismiss the bar and the next call '
              'would race the in-flight dismissal animation.',
        );
      },
    );
  });

  registerDismissSnackBarCounterGroup();

  group('e2eDismissSnackBarIfPresent — constant pin', () {
    test('kE2eDefaultSnackBarDismissTimeout matches legacy 2 s budget', () {
      // The legacy inline SnackBar branch of e2eDismissTransientUi used a
      // hardcoded 2 s timeout. A silent drift here would either inflate the
      // per-call dismiss window (regressing AC9 aggregate wall-clock) or
      // shrink it (risking false negatives when the SnackBar dismiss
      // animation runs slow under load).
      expect(
        kE2eDefaultSnackBarDismissTimeout,
        const Duration(seconds: 2),
        reason:
            'kE2eDefaultSnackBarDismissTimeout must preserve the legacy 2 s '
            'inline budget to keep AC9 aggregate wall-clock attribution '
            'stable across the lift.',
      );
    });
  });

  registerDismissSnackBarPerfAttributionGroup();
}
