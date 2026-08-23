/// Widget-test coverage for `e2eOpenNavalPanel`, the shared helper that
/// drives fleet E2E paths into the naval units panel from either the empire
/// rail (H6 site in `colonizethis_app/integration_test/`) or the first-fleet
/// map marker.
///
/// The prepump short-circuit branch (panel already mounted) is pinned by
/// `app/test/e2e_open_panel_prepump_test.dart`. This file pins the **other**
/// branches of the naval opener loop, mirroring the structurally similar
/// civilian opener pins in `app/test/e2e_open_civilian_panel_test.dart`:
///
///   - Empire rail tap on a synchronously-mounted panel (sync detect).
///   - First-fleet marker tap when the rail button is absent.
///   - Empire rail tap on a panel that mounts after a short delay (async
///     detect via the helper's `e2ePumpUntilConditionOrIdle` post-tap wait).
///   - Persistent absence of both triggers (helper must surface a
///     `TestFailure` rather than silently returning).
///
/// Because `integration_test/` is not part of the PR `quality` workflow
/// (`SPEC/program/e2e-integration-tests.md` § CI — `app_e2e_linux` lane is a
/// no-op), the widget-test layer carries the behavioural pins for the AC2
/// "single canonical opener" and AC5 "adaptive polling with pre-pump
/// short-circuit" contracts for this opener. The naval opener has had at
/// least one real defect previously (rail tap could time out because the
/// in-flight implementation used `e2eWaitUntilFound + fail()` instead of the
/// bounded `e2ePumpUntilConditionOrIdle` used by the civilian opener — see
/// GitHub PR #2555). Without these pins, a future refactor of the
/// rail/marker selection or the post-tap fallback window could silently
/// regress at the integration-test wall-clock layer with no unit-level
/// signal.
///
/// Refs GitHub #2336 (AC2 — shared helpers used by E2E tests; AC5 — adaptive
/// polling with pre-pump short-circuit; AC10 — no silent flakiness from
/// timeout regressions).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/e2e_open_naval_panel_hosts.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eOpenNavalPanel taps the empire rail button and detects the panel',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NavalRailHost()));
      expect(find.byKey(kEmpireNavalUnitsButtonKey), findsOneWidget);
      expect(find.byKey(kCtE2ENavalPanelRootKey), findsNothing);
      await e2eOpenNavalPanel(tester, timeout: const Duration(seconds: 5));
      expect(
        find.byKey(kCtE2ENavalPanelRootKey),
        findsOneWidget,
        reason:
            'After tapping the keyed empire naval rail button, the helper '
            'must detect the panel root on the next pump and return '
            '(Refs GitHub #2336 AC2 — single canonical opener).',
      );
    },
  );

  testWidgets('e2eOpenNavalPanel falls back to the first-fleet marker '
      'when the empire rail button is absent', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NavalMarkerOnlyHost()));
    expect(find.byKey(kEmpireNavalUnitsButtonKey), findsNothing);
    expect(find.byKey(kCtE2EOpenFirstFleetMarkerPanelKey), findsOneWidget);
    expect(find.byKey(kCtE2ENavalPanelRootKey), findsNothing);
    await e2eOpenNavalPanel(tester, timeout: const Duration(seconds: 5));
    expect(
      find.byKey(kCtE2ENavalPanelRootKey),
      findsOneWidget,
      reason:
          'When the empire rail button is not in the tree, the helper must '
          'tap the first-fleet map marker as the second canonical '
          'trigger (Refs GitHub #2336 AC2 — single canonical opener).',
    );
  });

  testWidgets(
    'e2eOpenNavalPanel returns once the panel root mounts asynchronously '
    'after the rail tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DelayedNavalPanelHost(mountAfter: Duration(milliseconds: 120)),
        ),
      );
      expect(find.byKey(kCtE2ENavalPanelRootKey), findsNothing);
      await e2eOpenNavalPanel(tester, timeout: const Duration(seconds: 5));
      expect(
        find.byKey(kCtE2ENavalPanelRootKey),
        findsOneWidget,
        reason:
            'Adaptive polling must keep pumping past the post-tap fallback '
            'window until the naval panel root mounts (Refs GitHub #2336 '
            'AC5 — condition-based wait, not a fixed sleep; also guards '
            'against PR #2555 regression where the rail tap could time out '
            'because tryOpen failed instead of bounded-polling).',
      );
    },
  );

  testWidgets(
    'e2eOpenNavalPanel times out with TestFailure when no opener surfaces',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      Object? caught;
      try {
        await e2eOpenNavalPanel(
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
            'Persistent absence of both the empire rail button and the '
            'first-fleet marker must surface a TestFailure rather than '
            'silently returning (Refs GitHub #2336 AC10 — no silent '
            'flakiness from timeout regressions).',
      );
    },
  );
}
