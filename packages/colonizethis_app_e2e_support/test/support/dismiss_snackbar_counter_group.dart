// Perf counter bump pins for `e2e_dismiss_snackbar_if_present_test.dart`
// (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_widget_tester_harness.dart';

void registerDismissSnackBarCounterGroup() {
  group('e2eDismissSnackBarIfPresent — perf counter bump pin', () {
    testWidgets(
      'emits exactly one E2E_COUNTER dismiss_snackbar_calls bump on success',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_perf_pin');
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
        expect(
          hasE2eCounterLine(
            lines,
            test: 'snackbar_perf_pin',
            name: 'dismiss_snackbar_calls',
            expectedValue: 1,
          ),
          isTrue,
          reason:
              'Success path must emit exactly one '
              'E2E_COUNTER|...|name=dismiss_snackbar_calls|value=1 marker so '
              'observer dashboards can attribute the cost of stranded '
              'SnackBars per scenario. Captured lines: $lines',
        );
        final bumpCount = lines
            .where(
              (line) => line.startsWith(
                'E2E_COUNTER|test=snackbar_perf_pin|name=dismiss_snackbar_calls|',
              ),
            )
            .length;
        expect(
          bumpCount,
          1,
          reason:
              'Success path must bump dismiss_snackbar_calls exactly once; '
              'a regression that double-bumped would inflate downstream '
              'counter aggregations. Captured lines: $lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_snackbar_calls when no SnackBar is mounted',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_perf_no_sb_pin');
        await pumpDismissMaterial(
          tester,
          const Scaffold(body: SizedBox()),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(tester, perf: perf);
        });

        expect(
          hasAnyE2eCounterLine(
            lines,
            test: 'snackbar_perf_no_sb_pin',
            name: 'dismiss_snackbar_calls',
          ),
          isFalse,
          reason:
              'No-SnackBar short-circuit must not emit the counter marker '
              '(the caller did not actually dismiss anything). Captured '
              'lines: $lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_snackbar_calls when no hit-testable action found',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_perf_no_action_pin');
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

        expect(
          hasAnyE2eCounterLine(
            lines,
            test: 'snackbar_perf_no_action_pin',
            name: 'dismiss_snackbar_calls',
          ),
          isFalse,
          reason:
              'No-hit-testable-action branch must not emit the counter '
              'marker (the helper returned false without tapping). Captured '
              'lines: $lines',
        );
      },
    );
  });
}
