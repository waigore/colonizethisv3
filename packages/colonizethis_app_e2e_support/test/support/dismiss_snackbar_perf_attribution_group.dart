// Inner-helper perf attribution pins for
// `e2e_dismiss_snackbar_if_present_test.dart` (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_inner_perf_timing.dart';
import 'dismiss_widget_tester_harness.dart';

void registerDismissSnackBarPerfAttributionGroup() {
  group('e2eDismissSnackBarIfPresent perf attribution', () {
    test('phase constant matches the documented `dismiss_snackbar` label', () {
      expect(
        kE2eDefaultDismissSnackBarPhase,
        'dismiss_snackbar',
        reason:
            'Phase constant must stay byte-equivalent so the AC8 baseline '
            'timing pipeline can key on the same phase=... label as the '
            'docs in `SPEC/program/e2e-integration-tests.md` § Determinism '
            '(Dismiss-snackbar inner perf attribution bullet).',
      );
    });

    testWidgets(
      'emits result=not_present without the dispatcher counter when no '
      'SnackBar is mounted',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_phase_pin');
        await pumpDismissMaterial(
          tester,
          const Scaffold(body: SizedBox()),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(tester, perf: perf);
        });

        expectSingleDismissTimingMeta(
          lines: lines,
          phase: kE2eDefaultDismissSnackBarPhase,
          resultMeta: 'not_present',
          capturedReasonSuffix:
              ' on the no-SnackBar short-circuit.',
        );
        expect(
          hasAnyE2eCounterLine(
            lines,
            test: 'snackbar_phase_pin',
            name: 'dismiss_snackbar_calls',
          ),
          isFalse,
          reason:
              'No-SnackBar short-circuit must not bump '
              '`dismiss_snackbar_calls` (the helper returned false without '
              'tapping). Captured: $lines',
        );
      },
    );

    testWidgets(
      'emits result=no_action without the dispatcher counter when SnackBar '
      'has no hit-testable TextButton',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_no_action_phase_pin');
        await pumpDismissMaterial(
          tester,
          DismissSnackBarHost(
            snackBar: const SnackBar(
              duration: Duration(seconds: 30),
              content: Text('no-action-content'),
            ),
          ),
        );
        await pumpDismissOverlaySettle(tester);

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(tester, perf: perf);
        });

        expectSingleDismissTimingMeta(
          lines: lines,
          phase: kE2eDefaultDismissSnackBarPhase,
          resultMeta: 'no_action',
          capturedReasonSuffix:
              ' on the no-hit-testable-action branch.',
        );
        expect(
          hasAnyE2eCounterLine(
            lines,
            test: 'snackbar_no_action_phase_pin',
            name: 'dismiss_snackbar_calls',
          ),
          isFalse,
          reason:
              'No-action branch must not bump `dismiss_snackbar_calls` (the '
              'helper returned false without tapping). Captured: $lines',
        );
      },
    );

    testWidgets('emits result=tapped alongside the dispatcher counter when the '
        'hit-testable action is dismissed', (WidgetTester tester) async {
      final perf = E2ePerfLog('snackbar_tapped_phase_pin');
      await pumpDismissMaterial(
        tester,
        DismissSnackBarHost(
          snackBar: SnackBar(
            duration: const Duration(seconds: 30),
            content: const Text('snack-content'),
            action: SnackBarAction(label: 'Undo', onPressed: () {}),
          ),
        ),
      );
      await pumpDismissOverlaySettle(tester);

      late bool dismissed;
      final lines = await captureE2eDebugPrints(() async {
        dismissed = await e2eDismissSnackBarIfPresent(tester, perf: perf);
      });
      await pumpDismissPostTapSettle(tester);

      expect(dismissed, isTrue);
      expectSingleDismissTimingMeta(
        lines: lines,
        phase: kE2eDefaultDismissSnackBarPhase,
        resultMeta: 'tapped',
        capturedReasonSuffix: ' on the success path.',
      );
    });

    testWidgets(
      'no perf line emitted when perf is null (default opt-out contract)',
      (WidgetTester tester) async {
        await pumpDismissMaterial(
          tester,
          DismissSnackBarHost(
            snackBar: SnackBar(
              duration: const Duration(seconds: 30),
              content: const Text('quiet'),
              action: SnackBarAction(label: 'Undo', onPressed: () {}),
            ),
          ),
        );
        await pumpDismissOverlaySettle(tester);

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(tester);
        });
        await pumpDismissPostTapSettle(tester);

        expectNoDismissTimingForPhase(
          lines: lines,
          phase: kE2eDefaultDismissSnackBarPhase,
          capturedReasonSuffix: '',
        );
      },
    );

    testWidgets(
      'custom phaseName reaches the inner-helper emission and does NOT also '
      'emit under the default label',
      (WidgetTester tester) async {
        const customPhase = 'snackbar_custom_phase_label';
        final perf = E2ePerfLog('snackbar_custom_phase_pin');
        await pumpDismissMaterial(
          tester,
          DismissSnackBarHost(
            snackBar: SnackBar(
              duration: const Duration(seconds: 30),
              content: const Text('custom-phase'),
              action: SnackBarAction(label: 'Undo', onPressed: () {}),
            ),
          ),
        );
        await pumpDismissOverlaySettle(tester);

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(
            tester,
            perf: perf,
            phaseName: customPhase,
          );
        });
        await pumpDismissPostTapSettle(tester);

        final customTiming = e2eTimingLinesForPhase(lines, customPhase);
        expect(
          customTiming,
          hasLength(1),
          reason:
              'Custom phaseName must be threaded through to the inner-helper '
              'E2E_TIMING emission so distinct dispatch sites can stay '
              'separable in perf-timing dumps. Captured: $lines',
        );
        final defaultTiming = e2eTimingLinesForPhase(
          lines,
          kE2eDefaultDismissSnackBarPhase,
        );
        expect(
          defaultTiming,
          isEmpty,
          reason:
              'A custom phaseName must NOT also surface under the default '
              'phase label; otherwise scrapers that aggregate by the default '
              'phase would double-count custom-labelled calls.',
        );
      },
    );
  });
}
