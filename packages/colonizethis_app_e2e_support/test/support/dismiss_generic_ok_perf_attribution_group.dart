// Inner-helper perf attribution pins for
// `e2e_dismiss_generic_ok_if_present_test.dart` (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_inner_perf_timing.dart';
import 'dismiss_widget_tester_harness.dart';

void registerDismissGenericOkPerfAttributionGroup() {
  group('e2eDismissGenericOkIfPresent perf attribution', () {
    test(
      'phase constant matches the documented `dismiss_generic_ok` label',
      () {
        expect(
          kE2eDefaultDismissGenericOkPhase,
          'dismiss_generic_ok',
          reason:
              'Phase constant must stay byte-equivalent so the AC8 baseline '
              'timing pipeline can key on the same phase=... label as the '
              'docs in `SPEC/program/e2e-integration-tests.md` § Determinism '
              '(Dismiss-generic-OK inner perf attribution bullet).',
        );
      },
    );

    testWidgets(
      'emits result=not_present without the dispatcher counter when no '
      'hit-testable OK label is present',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_phase_not_present_pin');
        await pumpDismissMaterial(
          tester,
          const Scaffold(body: SizedBox()),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(tester, perf: perf);
        });

        expectSingleDismissTimingMeta(
          lines: lines,
          phase: kE2eDefaultDismissGenericOkPhase,
          resultMeta: 'not_present',
          capturedReasonSuffix: ' on the no-OK short-circuit.',
        );
        expect(
          hasAnyE2eCounterLine(
            lines,
            test: 'generic_ok_phase_not_present_pin',
            name: 'dismiss_generic_ok_calls',
          ),
          isFalse,
          reason:
              'No-OK short-circuit must not bump `dismiss_generic_ok_calls` '
              '(the helper returned false without tapping). Captured: $lines',
        );
      },
    );

    testWidgets(
      'emits result=tapped alongside the dispatcher counter when the OK '
      'label is dismissed',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_phase_tapped_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextButton(onPressed: () {}, child: const Text('OK')),
              ),
            ),
          ),
        );

        late bool dismissed;
        final lines = await captureE2eDebugPrints(() async {
          dismissed = await e2eDismissGenericOkIfPresent(tester, perf: perf);
        });
        await pumpDismissPostTapSettle(tester);

        expect(dismissed, isTrue);
        expectSingleDismissTimingMeta(
          lines: lines,
          phase: kE2eDefaultDismissGenericOkPhase,
          resultMeta: 'tapped',
          capturedReasonSuffix: ' on the success path.',
        );
      },
    );

    testWidgets(
      'no perf line emitted when perf is null (default opt-out contract)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextButton(onPressed: () {}, child: const Text('OK')),
              ),
            ),
          ),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(tester);
        });
        await pumpDismissPostTapSettle(tester);

        expectNoDismissTimingForPhase(
          lines: lines,
          phase: kE2eDefaultDismissGenericOkPhase,
          capturedReasonSuffix: '',
        );
      },
    );

    testWidgets(
      'custom phaseName reaches the inner-helper emission and does NOT also '
      'emit under the default label',
      (WidgetTester tester) async {
        const customPhase = 'generic_ok_custom_phase_label';
        final perf = E2ePerfLog('generic_ok_custom_phase_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextButton(onPressed: () {}, child: const Text('OK')),
              ),
            ),
          ),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(
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
          kE2eDefaultDismissGenericOkPhase,
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
