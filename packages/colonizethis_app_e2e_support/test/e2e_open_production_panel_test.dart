/// Widget-test coverage for `e2eOpenProductionPanel`, the shared helper used
/// by the full-turn E2E to enter the production screen from the empire rail
/// (Bottleneck 2 / H7 site in `colonizethis_app/integration_test/`).
///
/// The integration tests pay the realistic wall-clock cost of the helper, but
/// `integration_test/` is not part of the PR `quality` workflow
/// (`SPEC/program/e2e-integration-tests.md` § CI — `app_e2e_linux` lane is a
/// no-op). Widget-level pins keep the AC2/AC5 contract for this opener live
/// in the unit-test layer so a future refactor cannot silently regress the
/// short-circuit or tap-once-then-detect-mount paths.
///
/// The opener previously used `e2eWaitUntilFound + fail()` for the post-rail-
/// tap wait, mirroring the naval opener defect surfaced and fixed in PR #2555.
/// The production opener now uses `e2ePumpUntilConditionOrIdle` (bounded poll
/// without `fail()`) so a single rail-tap that fails to mount the panel does
/// not surface as a hard `TestFailure` from the inner wait — instead, the
/// outer opener loop dismisses any racing overlays/sheets and re-taps the
/// rail until the overall [timeout] elapses. The negative test below still
/// pins outer-timeout failure semantics.
///
/// Refs GitHub #2336 (AC2 — shared helpers used by E2E tests; AC5 — adaptive
/// polling with pre-pump short-circuit; AC10 — no silent flakiness from
/// timeout regressions); aligns with PR #2555 fix for the naval opener.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'support/open_production_panel_harness.dart';
import 'support/e2e_widget_pump_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eOpenProductionPanel short-circuits when panel root already mounted',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapE2eScaffold(
          KeyedSubtree(
            key: kCtE2EProductionPanelRootKey,
            child: Container(width: 200, height: 200, color: Colors.green),
          ),
        ),
      );
      final sw = Stopwatch()..start();
      await e2eOpenProductionPanel(tester);
      expect(
        sw.elapsed < const Duration(milliseconds: 200),
        isTrue,
        reason:
            'Already-mounted production panel root must return before the '
            'loop pays any rail-tap probing budget (Refs GitHub #2336 AC5).',
      );
    },
  );

  testWidgets(
    'e2eOpenProductionPanel taps the empire rail button and detects the panel',
    (WidgetTester tester) async {
      await tester.pumpWidget(wrapE2eApp(ProductionRailHarness()));
      expect(find.byKey(kEmpireProductionButtonKey), findsOneWidget);
      expect(find.byKey(kCtE2EProductionPanelRootKey), findsNothing);
      await e2eOpenProductionPanel(tester, timeout: const Duration(seconds: 5));
      expect(
        find.byKey(kCtE2EProductionPanelRootKey),
        findsOneWidget,
        reason:
            'After tapping the keyed production button, the helper must wait '
            'for the panel root to mount and return on the next pump '
            '(Refs GitHub #2336 AC2 — single canonical opener).',
      );
    },
  );

  testWidgets(
    'e2eOpenProductionPanel returns once the panel root mounts asynchronously',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapE2eApp(
          DelayedProductionPanelHarness(
            mountAfter: Duration(milliseconds: 120),
          ),
        ),
      );
      expect(find.byKey(kCtE2EProductionPanelRootKey), findsNothing);
      await e2eOpenProductionPanel(tester, timeout: const Duration(seconds: 5));
      expect(
        find.byKey(kCtE2EProductionPanelRootKey),
        findsOneWidget,
        reason:
            'Adaptive polling must keep pumping past the post-tap fallback '
            'window until the panel root mounts (Refs GitHub #2336 AC5 — '
            'condition-based wait).',
      );
    },
  );

  testWidgets(
    'e2eOpenProductionPanel times out with TestFailure when no entry surfaces',
    (WidgetTester tester) async {
      await pumpE2eBareScaffold(tester);
      Object? caught;
      try {
        await e2eOpenProductionPanel(
          tester,
          timeout: const Duration(milliseconds: 250),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Persistent absence of both the production button and panel root '
            'must surface a TestFailure rather than silently returning '
            '(Refs GitHub #2336 AC10 — no silent flakiness).',
      );
    },
  );

  testWidgets(
    'e2eOpenProductionPanel timeout failure surfaces the outer opener message, '
    'not the inner post-tap wait',
    (WidgetTester tester) async {
      // Rail button is present but tapping it never mounts the panel, so the
      // inner post-rail-tap wait must exhaust without `fail()`-ing the helper.
      // Once the outer timeout elapses, the failure must come from the outer
      // `Timed out opening production panel` path (PR #2555 contract for the
      // naval opener; this pins the same contract for production).
      await tester.pumpWidget(wrapE2eApp(NoOpProductionRailHarness()));
      expect(find.byKey(kEmpireProductionButtonKey), findsOneWidget);
      expect(find.byKey(kCtE2EProductionPanelRootKey), findsNothing);
      Object? caught;
      try {
        await e2eOpenProductionPanel(
          tester,
          // Small outer timeout keeps the test bounded; the inner 5s post-tap
          // poll is the path under test — it must return without `fail()`.
          timeout: const Duration(milliseconds: 250),
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<TestFailure>());
      final message = caught.toString();
      expect(
        message,
        contains('Timed out opening production panel'),
        reason:
            'After the post-rail-tap wait is bounded by '
            '`e2ePumpUntilConditionOrIdle` (no `fail()`), only the outer '
            'opener loop owns the timeout failure path. A regression to '
            '`e2eWaitUntilFound` would surface the inner `Timed out after Ns '
            'waiting for ...` message instead (Refs GitHub #2336; aligns '
            'with PR #2555 fix for the naval opener).',
      );
      expect(
        message,
        isNot(contains('wait_until_production_panel_after_rail_tap')),
        reason:
            'The legacy inner-wait phase name must not appear in any failure '
            'path; the helper now uses `pump_until_...` semantics so the '
            'outer loop can dismiss racing overlays and retry the rail tap '
            '(Refs GitHub #2336).',
      );
    },
  );
}
