// Fixtures and perf counter pins for
// `e2e_dismiss_generic_ok_if_present_test.dart` (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_widget_tester_harness.dart';

/// Hosts an `OK` label inside a `Stack` with an opaque `AbsorbPointer`
/// overlay on top, so the label is **mounted but non-hit-testable**.
class DismissCoveredOkLabel extends StatelessWidget {
  const DismissCoveredOkLabel({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 48,
      child: absorbPointerCover(
        child: TextButton(onPressed: onTap, child: Text(label)),
      ),
    );
  }
}

void registerDismissGenericOkCounterGroup() {
  group('e2eDismissGenericOkIfPresent — perf counter bump pin', () {
    testWidgets(
      'emits exactly one E2E_COUNTER dismiss_generic_ok_calls bump on '
      'labelled-tap success',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_perf_pin');
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
        expect(
          hasE2eCounterLine(
            lines,
            test: 'generic_ok_perf_pin',
            name: 'dismiss_generic_ok_calls',
            expectedValue: 1,
          ),
          isTrue,
          reason:
              'Labelled-tap success must emit exactly one '
              'E2E_COUNTER|...|name=dismiss_generic_ok_calls|value=1 marker '
              'so observer dashboards can attribute the cost of stray '
              'top-level OK banners per scenario. Captured lines: $lines',
        );
        final bumpCount = lines
            .where(
              (line) => line.startsWith(
                'E2E_COUNTER|test=generic_ok_perf_pin|'
                'name=dismiss_generic_ok_calls|',
              ),
            )
            .length;
        expect(
          bumpCount,
          1,
          reason:
              'Success path must bump dismiss_generic_ok_calls exactly '
              'once; a regression that double-bumped would inflate '
              'downstream counter aggregations. Captured lines: $lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_generic_ok_calls when no OK label is present',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_perf_no_ok_pin');
        await pumpDismissMaterial(
          tester,
          const Scaffold(body: SizedBox()),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(tester, perf: perf);
        });

        expect(
          hasAnyE2eCounterLine(
            lines,
            test: 'generic_ok_perf_no_ok_pin',
            name: 'dismiss_generic_ok_calls',
          ),
          isFalse,
          reason:
              'No-OK short-circuit must not emit the counter marker (the '
              'helper returned false without tapping). Captured lines: '
              '$lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_generic_ok_calls when the only OK is covered',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_perf_covered_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: DismissCoveredOkLabel(label: 'OK', onTap: () {}),
              ),
            ),
          ),
        );

        final lines = await captureE2eDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(tester, perf: perf);
        });

        expect(
          hasAnyE2eCounterLine(
            lines,
            test: 'generic_ok_perf_covered_pin',
            name: 'dismiss_generic_ok_calls',
          ),
          isFalse,
          reason:
              'Covered-OK short-circuit must not emit the counter marker '
              '(the helper returned false without tapping). Captured '
              'lines: $lines',
        );
      },
    );
  });
}
