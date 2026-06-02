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

import 'dart:async';

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eOpenNavalPanel taps the empire rail button and detects the panel',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _NavalRailHarness()),
      );
      expect(find.byKey(kEmpireNavalUnitsButtonKey), findsOneWidget);
      expect(find.byKey(kCtE2ENavalPanelRootKey), findsNothing);
      await e2eOpenNavalPanel(
        tester,
        timeout: const Duration(seconds: 5),
      );
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

  testWidgets(
    'e2eOpenNavalPanel falls back to the first-fleet marker '
    'when the empire rail button is absent',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _NavalMarkerOnlyHarness()),
      );
      expect(find.byKey(kEmpireNavalUnitsButtonKey), findsNothing);
      expect(
        find.byKey(kCtE2EOpenFirstFleetMarkerPanelKey),
        findsOneWidget,
      );
      expect(find.byKey(kCtE2ENavalPanelRootKey), findsNothing);
      await e2eOpenNavalPanel(
        tester,
        timeout: const Duration(seconds: 5),
      );
      expect(
        find.byKey(kCtE2ENavalPanelRootKey),
        findsOneWidget,
        reason:
            'When the empire rail button is not in the tree, the helper must '
            'tap the first-fleet map marker as the second canonical '
            'trigger (Refs GitHub #2336 AC2 — single canonical opener).',
      );
    },
  );

  testWidgets(
    'e2eOpenNavalPanel returns once the panel root mounts asynchronously '
    'after the rail tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _DelayedNavalPanelHarness(
            mountAfter: Duration(milliseconds: 120),
          ),
        ),
      );
      expect(find.byKey(kCtE2ENavalPanelRootKey), findsNothing);
      await e2eOpenNavalPanel(
        tester,
        timeout: const Duration(seconds: 5),
      );
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

/// Test harness that mounts the naval panel root synchronously when the
/// keyed empire rail button is tapped, so the helper detects the panel on
/// the very next frame.
class _NavalRailHarness extends StatefulWidget {
  const _NavalRailHarness();

  @override
  State<_NavalRailHarness> createState() => _NavalRailHarnessState();
}

class _NavalRailHarnessState extends State<_NavalRailHarness> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kEmpireNavalUnitsButtonKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Naval'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ENavalPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// Test harness that exposes the first-fleet marker but no empire rail
/// button, so the helper must take the marker branch as the second canonical
/// trigger.
class _NavalMarkerOnlyHarness extends StatefulWidget {
  const _NavalMarkerOnlyHarness();

  @override
  State<_NavalMarkerOnlyHarness> createState() =>
      _NavalMarkerOnlyHarnessState();
}

class _NavalMarkerOnlyHarnessState extends State<_NavalMarkerOnlyHarness> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kCtE2EOpenFirstFleetMarkerPanelKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Marker'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ENavalPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// Test harness that mounts the naval panel root only after an in-test
/// timer fires so the helper exercises its adaptive post-tap waits before
/// returning. The keyed empire rail button drives the schedule, mirroring
/// the civilian async harness pattern in
/// `app/test/e2e_open_civilian_panel_test.dart` and the production-panel
/// async harness in `app/test/e2e_open_production_panel_test.dart`.
class _DelayedNavalPanelHarness extends StatefulWidget {
  const _DelayedNavalPanelHarness({required this.mountAfter});

  final Duration mountAfter;

  @override
  State<_DelayedNavalPanelHarness> createState() =>
      _DelayedNavalPanelHarnessState();
}

class _DelayedNavalPanelHarnessState
    extends State<_DelayedNavalPanelHarness> {
  bool _panelOpen = false;
  bool _scheduled = false;

  void _handleTap() {
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    Timer(widget.mountAfter, () {
      if (!mounted) {
        return;
      }
      setState(() => _panelOpen = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kEmpireNavalUnitsButtonKey,
            onPressed: _handleTap,
            child: const Text('Naval'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ENavalPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}
