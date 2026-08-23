/// Widget-test coverage for `e2eAwaitPanelOpenerRailHitTestable`, the shared
/// pre-tap rail/marker hit-testable wait used by `e2eOpenCivilianPanel`,
/// `e2eOpenNavalPanel`, and `e2eOpenProductionPanel` to defend against
/// transient overlays that cover a panel opener trigger before the outer
/// loop's `e2eEnsureVisibleAndTapHitTestable` tap is dispatched.
///
/// The helper is the deferred slice from PR #2782: that PR unified the
/// inner `tryOpen` tap recipe into [e2eEnsureVisibleAndTapHitTestable] but
/// left the outer-loop pre-tap wait inlined only in the naval opener
/// (`wait_until_naval_rail_hit_testable` / `wait_until_naval_marker_hit_
/// testable` since PR #2555). Lifting the recipe into one shared primitive
/// gives all three openers identical pre-tap settle semantics
/// byte-equivalently.
///
/// Because `integration_test/` is not part of the PR `quality` workflow
/// (`SPEC/program/e2e-integration-tests.md` § CI — `app_e2e_linux` lane is
/// a no-op), the widget-test layer carries the behavioural pins for the
/// AC1 "single canonical shared helper" and AC10 "no silent flakiness
/// from off-screen-trigger drops" contracts. Without these pins, a future
/// refactor that re-inlined the pre-tap wait inconsistently across the
/// three openers could silently regress at the integration-test
/// wall-clock layer with no unit-level signal.
///
/// Refs GitHub #2336 (AC1 — shared helpers; AC2 — single canonical
/// implementation; AC10 — no silent flakiness from timeout regressions).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'support/panel_opener_rail_harness.dart';
import 'support/e2e_widget_pump_harness.dart';

const _kPrimaryKey = ValueKey<String>('e2e_apohh_primary');
const _kSecondaryKey = ValueKey<String>('e2e_apohh_secondary');

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eAwaitPanelOpenerRailHitTestable returns immediately when primary is '
    'already hit-testable (no pump, no perf event)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapE2eApp(PrimaryHitTestableHarness(primaryKey: _kPrimaryKey)),
      );
      expect(find.byKey(_kPrimaryKey), findsOneWidget);
      expect(find.byKey(_kPrimaryKey).hitTestable(), findsOneWidget);
      final sw = Stopwatch()..start();
      await e2eAwaitPanelOpenerRailHitTestable(
        tester,
        primary: find.byKey(_kPrimaryKey),
        secondary: find.byKey(_kSecondaryKey),
        phaseName: 'wait_until_test_rail_hit_testable',
      );
      expect(
        sw.elapsed < const Duration(milliseconds: 50),
        isTrue,
        reason:
            'Already-hit-testable primary must short-circuit before paying '
            'any pump cycles so the no-overlay common case is byte-'
            'equivalent to the pre-#2336 civilian/production openers '
            '(Refs GitHub #2336 AC1 fast path).',
      );
    },
  );

  testWidgets(
    'e2eAwaitPanelOpenerRailHitTestable returns immediately when secondary is '
    'hit-testable but primary is not yet rendered',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapE2eApp(SecondaryOnlyHarness(secondaryKey: _kSecondaryKey)),
      );
      expect(find.byKey(_kPrimaryKey), findsNothing);
      expect(find.byKey(_kSecondaryKey).hitTestable(), findsOneWidget);
      final sw = Stopwatch()..start();
      await e2eAwaitPanelOpenerRailHitTestable(
        tester,
        primary: find.byKey(_kPrimaryKey),
        secondary: find.byKey(_kSecondaryKey),
        phaseName: 'wait_until_test_rail_hit_testable',
      );
      expect(
        sw.elapsed < const Duration(milliseconds: 50),
        isTrue,
        reason:
            'When primary is absent and secondary is already hit-testable, '
            'the helper must short-circuit too — the naval opener calls '
            'this with [marker, rail] when only the marker has rendered, '
            'so a regression that always required primary would pay an '
            'unnecessary pump cycle on every fleet-reach loop iteration '
            '(Refs GitHub #2336 AC1).',
      );
    },
  );

  testWidgets('e2eAwaitPanelOpenerRailHitTestable waits until primary becomes '
      'hit-testable when initially obscured', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapE2eApp(
        DelayedPrimaryHitTestableHarness(
          primaryKey: _kPrimaryKey,
          uncoverAfter: Duration(milliseconds: 120),
        ),
      ),
    );
    expect(find.byKey(_kPrimaryKey), findsOneWidget);
    expect(
      find.byKey(_kPrimaryKey).hitTestable(),
      findsNothing,
      reason:
          'Test fixture must start with the primary trigger covered so '
          'the pump-and-poll branch is actually exercised.',
    );
    await e2eAwaitPanelOpenerRailHitTestable(
      tester,
      primary: find.byKey(_kPrimaryKey),
      secondary: find.byKey(_kSecondaryKey),
      timeout: const Duration(seconds: 2),
      phaseName: 'wait_until_test_rail_hit_testable',
    );
    expect(
      find.byKey(_kPrimaryKey).hitTestable(),
      findsOneWidget,
      reason:
          'After the obscuring overlay clears within the helper '
          'timeout, the helper must observe the now-hit-testable '
          'primary and return without throwing (Refs GitHub #2336 '
          'AC10 — no silent flakiness from off-screen-trigger drops).',
    );
  });

  testWidgets(
    'e2eAwaitPanelOpenerRailHitTestable surfaces TestFailure when neither '
    'primary nor secondary becomes hit-testable within timeout',
    (WidgetTester tester) async {
      await pumpE2eBareScaffold(tester);
      Object? caught;
      try {
        await e2eAwaitPanelOpenerRailHitTestable(
          tester,
          primary: find.byKey(_kPrimaryKey),
          secondary: find.byKey(_kSecondaryKey),
          timeout: const Duration(milliseconds: 100),
          phaseName: 'wait_until_test_rail_hit_testable',
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Persistent absence of both finders must surface a TestFailure '
            'inside the inner wait so a permanently obscured rail trigger '
            'fails with a useful diagnostic message instead of silently '
            'consuming the outer opener loop budget. Matches the naval '
            'opener behaviour the inline `e2eWaitUntilAnyFinderHitTestable` '
            'call has carried since PR #2555 (Refs GitHub #2336 AC10).',
      );
    },
  );

  testWidgets(
    'e2eAwaitPanelOpenerRailHitTestable accepts a null secondary (production '
    'opener path)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapE2eApp(PrimaryHitTestableHarness(primaryKey: _kPrimaryKey)),
      );
      await e2eAwaitPanelOpenerRailHitTestable(
        tester,
        primary: find.byKey(_kPrimaryKey),
        phaseName: 'wait_until_test_rail_hit_testable',
      );
      expect(
        find.byKey(_kPrimaryKey).hitTestable(),
        findsOneWidget,
        reason:
            'The production opener calls this without a secondary marker '
            'finder; the helper must accept that and short-circuit on '
            'primary hit-testability alone (Refs GitHub #2336 AC1).',
      );
    },
  );
}
