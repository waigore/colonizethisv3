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
  });
}
