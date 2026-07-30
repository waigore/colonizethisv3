// Perf counter bump pins for `e2e_dismiss_alert_dialog_if_present_test.dart`
// (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_widget_tester_harness.dart';

void registerDismissAlertDialogCounterGroup() {
  group('e2eDismissAlertDialogIfPresent — perf counter bump pin', () {
    testWidgets(
      'emits exactly one E2E_COUNTER dismiss_alert_dialog_calls bump on '
      'labelled-tap success',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('alert_dialog_perf_pin');
        await pumpDismissPostFrameAlertDialog(
          tester,
          (context) => AlertDialog(
            title: const Text('counter-success'),
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
        expect(
          hasE2eCounterLine(
            lines,
            test: 'alert_dialog_perf_pin',
            name: 'dismiss_alert_dialog_calls',
            expectedValue: 1,
          ),
          isTrue,
          reason:
              'Labelled-tap success must emit exactly one '
              'E2E_COUNTER|...|name=dismiss_alert_dialog_calls|value=1 '
              'marker so observer dashboards can attribute the cost of '
              'stray AlertDialogs per scenario. Captured lines: $lines',
        );
        final bumpCount = lines
            .where(
              (line) => line.startsWith(
                'E2E_COUNTER|test=alert_dialog_perf_pin|'
                'name=dismiss_alert_dialog_calls|',
              ),
            )
            .length;
        expect(
          bumpCount,
          1,
          reason:
              'Success path must bump dismiss_alert_dialog_calls exactly '
              'once; a regression that double-bumped would inflate '
              'downstream counter aggregations. Captured lines: $lines',
        );
      },
    );

    testWidgets(
      'emits a single bump on handlePopRoute fallback (any successful '
      'dismissal attempt counts)',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('alert_dialog_fallback_perf_pin');
        await pumpDismissPostFrameAlertDialog(
          tester,
          (context) => const AlertDialog(
            title: Text('counter-fallback'),
            content: Text('No labelled actions'),
          ),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissAlertDialogIfPresent(tester, perf: perf);
        });
        await pumpDismissPostTapSettle(tester);

        expect(
          hasE2eCounterLine(
            lines,
            test: 'alert_dialog_fallback_perf_pin',
            name: 'dismiss_alert_dialog_calls',
            expectedValue: 1,
          ),
          isTrue,
          reason:
              'handlePopRoute fallback must also count as a successful '
              'dismissal attempt — the counter measures "stray AlertDialogs '
              'observed", not "labelled-button taps". Captured lines: $lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_alert_dialog_calls when no AlertDialog is mounted',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('alert_dialog_perf_no_dialog_pin');
        await pumpDismissMaterial(
          tester,
          const Scaffold(body: SizedBox()),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissAlertDialogIfPresent(tester, perf: perf);
        });

        expect(
          hasAnyE2eCounterLine(
            lines,
            test: 'alert_dialog_perf_no_dialog_pin',
            name: 'dismiss_alert_dialog_calls',
          ),
          isFalse,
          reason:
              'No-AlertDialog short-circuit must not emit the counter '
              'marker (the helper returned false without tapping or '
              'popping). Captured lines: $lines',
        );
      },
    );
  });
}
