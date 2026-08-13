library;

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dismiss_widget_tester_harness.dart';

void registerDismissTransientUiPerfGroup() {
  group('e2eDismissTransientUi perf attribution', () {
    test(
      'phase constant matches the documented `dismiss_transient_ui` label',
      () {
        expect(
          kE2eDefaultDismissTransientUiPhase,
          'dismiss_transient_ui',
          reason:
              'Phase constant must stay byte-equivalent so the AC8 baseline '
              'timing pipeline can key on the same phase=... label as the '
              'docs in `SPEC/program/e2e-integration-tests.md` § Determinism '
              '(Dismiss-transient-UI dispatch perf attribution bullet).',
        );
      },
    );

    testWidgets(
      'emits result=broad_sweep with the dispatcher counter still bumping '
      'when no transient UI is present',
      (WidgetTester tester) async {
        // Empty tree → none of the early-return branches fire, so the
        // dispatcher must report `result=broad_sweep` (the fall-through
        // path) and still bump `dismiss_transient_ui_calls` once on entry.
        await tester.pumpWidget(
          wrapDismissMaterial(const Scaffold(body: SizedBox())),
        );
        final perf = E2ePerfLog('pin_dismiss_transient_ui');
        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissTransientUi(tester, perf: perf);
        });

        final dispatcherCounter = lines
            .where((line) => line.contains('name=dismiss_transient_ui_calls'))
            .toList();
        expect(
          dispatcherCounter,
          hasLength(1),
          reason:
              'The dispatcher counter `dismiss_transient_ui_calls` must bump '
              'exactly once on entry regardless of which branch handles the '
              'call so legacy log scrapers that aggregate dispatch '
              'invocations stay stable.',
        );

        final dispatcherTiming = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultDismissTransientUiPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          dispatcherTiming,
          hasLength(1),
          reason:
              'Exactly one dispatcher-level `E2E_TIMING|phase=...` line must '
              'be emitted per call so suite aggregators do not double-count '
              'the dispatch wall-clock.',
        );
        expect(
          dispatcherTiming.single,
          contains('|meta=result=broad_sweep'),
          reason:
              'An empty-tree dispatch falls through every early-return '
              'branch, so the dispatcher must report `result=broad_sweep` '
              'so the AC8 timing pipeline can separate fast labelled-branch '
              'returns from the broad-sweep tail.',
        );
      },
    );

    testWidgets('emits result=snackbar when a SnackBar action is dispatched', (
      WidgetTester tester,
    ) async {
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

      final perf = E2ePerfLog('pin_dismiss_transient_ui');
      final lines = await captureE2eDebugPrints(() async {
        await e2eDismissTransientUi(tester, perf: perf);
      });

      final dispatcherTiming = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultDismissTransientUiPhase') &&
                line.startsWith('E2E_TIMING|'),
          )
          .toList();
      expect(
        dispatcherTiming,
        hasLength(1),
        reason:
            'Exactly one dispatcher-level `E2E_TIMING|phase=...` line must '
            'be emitted on a snackbar dispatch so the AC8 timing pipeline '
            'attributes the dispatch wall-clock without losing the inner '
            'snackbar helper attribution.',
      );
      expect(
        dispatcherTiming.single,
        contains('|meta=result=snackbar'),
        reason:
            'A snackbar dispatch must report `result=snackbar` so the AC8 '
            'timing pipeline can separate snackbar dispatches from other '
            'early-return branches and the broad-sweep tail.',
      );
    });

    testWidgets('emits result=generic_ok when a top-level OK is dispatched', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButton(onPressed: () {}, child: const Text('OK')),
            ),
          ),
        ),
      );
      final perf = E2ePerfLog('pin_dismiss_transient_ui');
      final lines = await captureE2eDebugPrints(() async {
        await e2eDismissTransientUi(tester, perf: perf);
      });

      final dispatcherTiming = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultDismissTransientUiPhase') &&
                line.startsWith('E2E_TIMING|'),
          )
          .toList();
      expect(
        dispatcherTiming,
        hasLength(1),
        reason:
            'A top-level OK dispatch must emit exactly one dispatcher-level '
            '`E2E_TIMING|phase=dismiss_transient_ui` line so the AC8 '
            'pipeline never double-counts the dispatch wall-clock.',
      );
      expect(
        dispatcherTiming.single,
        contains('|meta=result=generic_ok'),
        reason:
            'A top-level OK dispatch must report `result=generic_ok` so '
            'the AC8 pipeline can separate generic-OK dispatches from the '
            'sibling alert-dialog labelled-close path that also includes '
            '`OK` in its label priority list.',
      );
    });

    testWidgets(
      'emits result=alert_dialog when a labelled AlertDialog action is '
      'dispatched',
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

        final perf = E2ePerfLog('pin_dismiss_transient_ui');
        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissTransientUi(tester, perf: perf);
        });
        // Allow dismissal animation to settle so the dispatcher does not
        // race the post-tap unmount; this does not affect the captured
        // perf markers above.
        await tester.pump(const Duration(milliseconds: 250));

        final dispatcherTiming = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultDismissTransientUiPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          dispatcherTiming,
          hasLength(1),
          reason:
              'An AlertDialog dispatch must emit exactly one dispatcher-level '
              '`E2E_TIMING|phase=dismiss_transient_ui` line so the AC8 '
              'pipeline never double-counts the dispatch wall-clock.',
        );
        expect(
          dispatcherTiming.single,
          contains('|meta=result=alert_dialog'),
          reason:
              'An AlertDialog dispatch must report `result=alert_dialog` so '
              'the AC8 pipeline can separate AlertDialog dispatches from '
              'the snackbar / generic-OK / broad-sweep paths.',
        );
      },
    );

    testWidgets('emits no dispatcher-level timing when perf is null (default), '
        'preserving the opt-in attribution contract', (
      WidgetTester tester,
    ) async {
      // Default `perf: null` must not emit any dispatcher-level
      // `E2E_TIMING|phase=dismiss_transient_ui` line so legacy callers
      // that opt out of attribution keep their byte-quiet contract. The
      // inner helpers also stay byte-quiet because they only emit when a
      // non-null perf is threaded through.
      await tester.pumpWidget(
        wrapDismissMaterial(const Scaffold(body: SizedBox())),
      );
      final lines = await captureE2eDebugPrints(() async {
        await e2eDismissTransientUi(tester);
      });

      final dispatcherTiming = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultDismissTransientUiPhase'),
          )
          .toList();
      expect(
        dispatcherTiming,
        isEmpty,
        reason:
            'Default `perf: null` must NOT emit any dispatcher-level '
            'attribution markers so callers that opt out of attribution '
            '(the legacy widget-test pins, ad-hoc scenarios, future '
            'low-overhead integration paths) keep their byte-quiet '
            'contract.',
      );
    });

    testWidgets('a custom phaseName overrides the default dispatcher label', (
      WidgetTester tester,
    ) async {
      // Distinct dispatch sites can pass their own phaseName to keep
      // their timing markers separable in perf-timing dumps. The
      // dispatcher counter and the result=... taxonomy must stay the
      // same; only the phase=... label changes.
      const customPhase = 'dismiss_transient_ui_custom_call_site';
      await tester.pumpWidget(
        wrapDismissMaterial(const Scaffold(body: SizedBox())),
      );
      final perf = E2ePerfLog('pin_dismiss_transient_ui');
      final lines = await captureE2eDebugPrints(() async {
        await e2eDismissTransientUi(tester, perf: perf, phaseName: customPhase);
      });

      final customTiming = lines
          .where(
            (line) =>
                line.contains('phase=$customPhase') &&
                line.startsWith('E2E_TIMING|'),
          )
          .toList();
      expect(
        customTiming,
        hasLength(1),
        reason:
            'Custom phaseName must reach the dispatcher-level timing '
            'emission so distinct dispatch sites can be filtered '
            'independently in AC8 perf-timing dumps.',
      );
      expect(
        customTiming.single,
        contains('|meta=result=broad_sweep'),
        reason:
            'The result=... taxonomy must be independent of phaseName so '
            'a custom dispatch site still reports the same branch tags '
            '(here `broad_sweep` for the empty-tree fall-through).',
      );

      // Match the full `phase=<label>|` field so a custom phaseName that
      // legitimately contains the default label as a substring (here
      // `dismiss_transient_ui_custom_call_site`) does not falsely register
      // as a duplicate marker. The trailing `|` is the canonical field
      // separator used in every `E2E_TIMING|...` line emitted by
      // `E2ePerfLog.timing`.
      final defaultTiming = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultDismissTransientUiPhase|'),
          )
          .toList();
      expect(
        defaultTiming,
        isEmpty,
        reason:
            'A non-default phaseName must not also emit a marker keyed '
            'on the default label, or AC8 aggregators would double-count '
            'the same dispatch under two phase keys.',
      );
    });
  });
}
