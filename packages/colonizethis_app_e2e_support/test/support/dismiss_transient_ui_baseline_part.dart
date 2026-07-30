part of '../e2e_dismiss_transient_ui_test.dart';

void registerDismissTransientUiBaselineGroup() {
  testWidgets(
    'e2eDismissTransientUi short-circuits when no transient UI is present',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapDismissMaterial(const Scaffold(body: SizedBox())),
      );
      final sw = Stopwatch()..start();
      await e2eDismissTransientUi(tester);
      expect(
        sw.elapsed < const Duration(milliseconds: 150),
        isTrue,
        reason:
            'Empty transient-UI tree must return before paying any pump frame '
            '(GitHub #2336 AC5: prepump short-circuit parity with sibling '
            'panel-opener helpers).',
      );
    },
  );

  testWidgets(
    'e2eDismissTransientUi taps SnackBar action and removes the SnackBar',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapDismissMaterial(
          DismissSnackBarHost(
            snackBar: SnackBar(
              duration: const Duration(seconds: 30),
              content: const Text('snack-content'),
              action: SnackBarAction(label: 'Undo', onPressed: () {}),
            ),
          ),
        ),
      );
      await pumpDismissOverlaySettle(tester);
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'Test fixture must surface a SnackBar before the helper runs.',
      );

      await e2eDismissTransientUi(tester);
      // Allow the SnackBar dismissal animation to settle within the
      // helper's 2s pump-until-empty budget.
      await pumpDismissPostTapSettle(tester);

      expect(
        find.byType(SnackBar),
        findsNothing,
        reason:
            'SnackBar with a tappable TextButton action must be dismissed via '
            'the action tap (e2eDismissTransientUi SnackBar branch) so the '
            'next caller does not race a still-mounted overlay.',
      );
    },
  );

  testWidgets('e2eDismissTransientUi taps a top-level OK button', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrapDismissCentered(
        TextButton(
          onPressed: () {
            tapped = true;
          },
          child: const Text('OK'),
        ),
      ),
    );

    await e2eDismissTransientUi(tester);

    expect(
      tapped,
      isTrue,
      reason:
          'Top-level OK button must be tapped by the OK branch of '
          'e2eDismissTransientUi when no SnackBar/AlertDialog/BottomSheet '
          'is present.',
    );
  });

  testWidgets(
    'e2eDismissTransientUi taps a labelled Close action on an AlertDialog',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapDismissMaterial(
          DismissPostFrameDialogHost(
            dialogBuilder: (_) => AlertDialog(
              title: const Text('alert-title'),
              content: const Text('alert-content'),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(tester.element(find.text('Close'))).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
      await pumpDismissOverlaySettle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await e2eDismissTransientUi(tester);
      // Dialog dismissal animations need a few extra frames after the
      // helper returns to fully unmount the route.
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason:
            'AlertDialog with a labelled Close action must be dismissed via '
            'the labelled-button branch (preferred over the pop-route '
            'fallback) so future calls do not race an extra pop.',
      );
    },
  );

  testWidgets(
    'e2eDismissTransientUi pops an AlertDialog with no recognised label',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapDismissMaterial(
          DismissPostFrameDialogHost(
            dialogBuilder: (_) => const AlertDialog(
              title: Text('alert-title'),
              content: Text('alert-content'),
              actions: <Widget>[],
            ),
          ),
        ),
      );
      await pumpDismissOverlaySettle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await e2eDismissTransientUi(tester);
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason:
            'AlertDialog with none of {Close, OK, Cancel, Yes} must be '
            'dismissed via the handlePopRoute fallback so the helper never '
            'returns with a stranded modal that blocks subsequent panel '
            'opener calls.',
      );
    },
  );

  // Perf-attribution group (Refs GitHub #2336 AC8 baseline timing):
  // Pins the dispatcher-level `E2E_TIMING|phase=dismiss_transient_ui` marker
  // and its `result=...` meta tag for every branch the helper can reach
  // (`intro_advanced`, `snackbar`, `generic_ok`, `alert_dialog`,
  // `broad_sweep`), plus the opt-out contract when `perf: null` is passed.
  // The dispatcher counter `dismiss_transient_ui_calls` keeps bumping on
  // entry regardless of branch so legacy log scrapers stay stable.
  //
  // Mirrors the perf-attribution group landed for
  // `e2eAdvanceGameStartIntroUntilDismissed` (PR #2966) and
  // `e2eWaitForMapHudAfterNewGameStart` (PR #2960). The integration suite
  // cannot validate the dispatcher attribution directly today
  // (`app_e2e_linux` is a no-op per `SPEC/program/e2e-integration-tests.md` §
  // CI), so this widget-test layer is the only per-PR pin for the new
  // dispatch markers and their meta-tag taxonomy.
}
