// Perf counter bump pins for
// `e2e_dismiss_ct_dialog_shell_broad_sweep_if_present_test.dart`
// (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_broad_sweep_fixtures.dart';
import 'dismiss_widget_tester_harness.dart';

void registerDismissBroadSweepCounterGroup() {
  group(
    'e2eDismissCtDialogShellBroadSweepIfPresent — perf counter bump pin',
    () {
      testWidgets(
        'emits exactly one E2E_COUNTER bump on labelled-tap success',
        (WidgetTester tester) async {
          final perf = E2ePerfLog('shell_broad_sweep_perf_pin');
          await tester.pumpWidget(
            wrapDismissCentered(
              DismissCtDialogShellHost(
                builder: (context, close) =>
                    TextButton(onPressed: close, child: const Text('Cancel')),
              ),
            ),
          );

          late bool dismissed;
          final lines = await captureE2eDebugPrints(() async {
            dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
              tester,
              perf: perf,
            );
          });

          expect(dismissed, isTrue);
          expect(
            hasE2eCounterLine(
              lines,
              test: 'shell_broad_sweep_perf_pin',
              name: 'dismiss_ct_dialog_shell_broad_sweep_calls',
              expectedValue: 1,
            ),
            isTrue,
            reason:
                'Labelled-tap success must emit exactly one '
                'E2E_COUNTER|...|name=dismiss_ct_dialog_shell_broad_sweep_calls'
                '|value=1 marker so observer dashboards can attribute the '
                'cost of stray CtDialogShell overlays per scenario. '
                'Captured lines: $lines',
          );
          final bumpCount = lines
              .where(
                (line) => line.startsWith(
                  'E2E_COUNTER|test=shell_broad_sweep_perf_pin|'
                  'name=dismiss_ct_dialog_shell_broad_sweep_calls|',
                ),
              )
              .length;
          expect(
            bumpCount,
            1,
            reason:
                'Success path must bump '
                'dismiss_ct_dialog_shell_broad_sweep_calls exactly once; '
                'a regression that double-bumped would inflate downstream '
                'counter aggregations. Captured lines: $lines',
          );
        },
      );

      testWidgets(
        'emits a single bump on handlePopRoute fallback (any successful '
        'dismissal attempt counts)',
        (WidgetTester tester) async {
          final perf = E2ePerfLog('shell_broad_sweep_fallback_perf_pin');
          await tester.pumpWidget(
            wrapDismissMaterial(
              const DismissPostFrameDialogHost(
                dialogBuilder:
                    dismissBroadSweepRouteShellNoCandidatesPerfBuilder,
              ),
            ),
          );
          await pumpDismissOverlaySettle(tester);

          final lines = await captureE2eDebugPrints(() async {
            await e2eDismissCtDialogShellBroadSweepIfPresent(
              tester,
              perf: perf,
            );
          });
          await pumpDismissPostTapSettle(tester);

          expect(
            hasE2eCounterLine(
              lines,
              test: 'shell_broad_sweep_fallback_perf_pin',
              name: 'dismiss_ct_dialog_shell_broad_sweep_calls',
              expectedValue: 1,
            ),
            isTrue,
            reason:
                'handlePopRoute fallback must also count as a successful '
                'dismissal attempt — the counter measures "stray '
                'CtDialogShells observed", not "labelled-button taps". '
                'Captured lines: $lines',
          );
        },
      );

      testWidgets(
        'does not emit dismiss_ct_dialog_shell_broad_sweep_calls when no '
        'CtDialogShell is mounted',
        (WidgetTester tester) async {
          final perf = E2ePerfLog('shell_broad_sweep_perf_no_shell_pin');
          await tester.pumpWidget(
            wrapDismissMaterial(const Scaffold(body: SizedBox())),
          );

          final lines = await captureE2eDebugPrints(() async {
            await e2eDismissCtDialogShellBroadSweepIfPresent(
              tester,
              perf: perf,
            );
          });

          expect(
            hasAnyE2eCounterLine(
              lines,
              test: 'shell_broad_sweep_perf_no_shell_pin',
              name: 'dismiss_ct_dialog_shell_broad_sweep_calls',
            ),
            isFalse,
            reason:
                'No-shell short-circuit must not emit the counter marker '
                '(the helper returned false without tapping or popping). '
                'Captured lines: $lines',
          );
        },
      );
    },
  );
}
