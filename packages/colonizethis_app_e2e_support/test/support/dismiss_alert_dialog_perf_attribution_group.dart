// Inner-helper perf attribution pins for
// `e2e_dismiss_alert_dialog_if_present_test.dart` (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_inner_perf_timing.dart';
import 'dismiss_widget_tester_harness.dart';

void registerDismissAlertDialogPerfAttributionGroup() {
  group('e2eDismissAlertDialogIfPresent perf attribution', () {
    test(
      'phase constant matches the documented `dismiss_alert_dialog` label',
      () {
        expect(
          kE2eDefaultDismissAlertDialogPhase,
          'dismiss_alert_dialog',
          reason:
              'Phase constant must stay byte-equivalent so the AC8 baseline '
              'timing pipeline can key on the same phase=... label as the '
              'docs in `SPEC/program/e2e-integration-tests.md` § Determinism '
              '(Dismiss-alert-dialog inner perf attribution bullet).',
        );
      },
    );

    testWidgets(
      'emits result=not_present without the dispatcher counter when no '
      'AlertDialog is mounted',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('alert_dialog_phase_not_present_pin');
        await pumpDismissMaterial(
          tester,
          const Scaffold(body: SizedBox()),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissAlertDialogIfPresent(tester, perf: perf);
        });

        expectSingleDismissTimingMeta(
          lines: lines,
          phase: kE2eDefaultDismissAlertDialogPhase,
          resultMeta: 'not_present',
          capturedReasonSuffix:
              ' on the no-AlertDialog short-circuit.',
        );
        expect(
          hasAnyE2eCounterLine(
            lines,
            test: 'alert_dialog_phase_not_present_pin',
            name: 'dismiss_alert_dialog_calls',
          ),
          isFalse,
          reason:
              'No-AlertDialog short-circuit must not bump '
              '`dismiss_alert_dialog_calls` (the helper returned false '
              'without tapping or popping). Captured: $lines',
        );
      },
    );

    testWidgets(
      'emits result=labelled_tap alongside the dispatcher counter when a '
      'labelled action is dispatched',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('alert_dialog_phase_labelled_tap_pin');
        await pumpDismissPostFrameAlertDialog(
          tester,
          (context) => AlertDialog(
            title: const Text('phase-labelled-tap'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );

        late bool dismissed;
        final lines = await captureE2eDebugPrints(() async {
          dismissed = await e2eDismissAlertDialogIfPresent(tester, perf: perf);
        });
        await pumpDismissPostTapSettle(tester);

        expect(dismissed, isTrue);
        expectSingleDismissTimingMeta(
          lines: lines,
          phase: kE2eDefaultDismissAlertDialogPhase,
          resultMeta: 'labelled_tap',
          capturedReasonSuffix:
              ' on the labelled-tap success path.',
        );
      },
    );

    testWidgets(
      'emits result=pop_route_fallback alongside the dispatcher counter '
      'when no labelled button is hit-testable',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('alert_dialog_phase_fallback_pin');
        await pumpDismissPostFrameAlertDialog(
          tester,
          (context) => const AlertDialog(
            title: Text('phase-fallback'),
            content: Text('No labelled actions'),
          ),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissAlertDialogIfPresent(tester, perf: perf);
        });
        await pumpDismissPostTapSettle(tester);

        expectSingleDismissTimingMeta(
          lines: lines,
          phase: kE2eDefaultDismissAlertDialogPhase,
          resultMeta: 'pop_route_fallback',
          capturedReasonSuffix:
              ' on the handlePopRoute fallback path.',
        );
      },
    );

    testWidgets(
      'no perf line emitted when perf is null (default opt-out contract)',
      (WidgetTester tester) async {
        await pumpDismissPostFrameAlertDialog(
          tester,
          (context) => AlertDialog(
            title: const Text('phase-quiet'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissAlertDialogIfPresent(tester);
        });
        await pumpDismissPostTapSettle(tester);

        expectNoDismissTimingForPhase(
          lines: lines,
          phase: kE2eDefaultDismissAlertDialogPhase,
          capturedReasonSuffix: '',
        );
      },
    );

    testWidgets(
      'custom phaseName reaches the inner-helper emission and does NOT also '
      'emit under the default label',
      (WidgetTester tester) async {
        const customPhase = 'alert_dialog_custom_phase_label';
        final perf = E2ePerfLog('alert_dialog_custom_phase_pin');
        await pumpDismissPostFrameAlertDialog(
          tester,
          (context) => AlertDialog(
            title: const Text('phase-custom'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissAlertDialogIfPresent(
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
          kE2eDefaultDismissAlertDialogPhase,
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
