/// Widget-test coverage for `e2eOpenCivilianPanel`, the shared helper that
/// drives full-turn and fleet E2E paths into the civilian units panel from
/// either the empire rail (H5 site in `colonizethis_app/integration_test/`)
/// or the first-civilian map marker.
///
/// The prepump short-circuit branch (panel already mounted) is pinned by
/// `app/test/e2e_open_panel_prepump_test.dart`. This file pins the **other**
/// branches of the opener loop:
///
///   - Empire rail tap on a mounted-synchronously panel (sync detect).
///   - First-civilian marker tap when the rail button is absent.
///   - Empire rail tap on a panel that mounts after a short delay (async
///     detect via the helper's adaptive condition-based wait).
///   - Persistent absence of both triggers (helper must surface a
///     `TestFailure` rather than silently returning).
///
/// Because `integration_test/` is not part of the PR `quality` workflow
/// (`SPEC/program/e2e-integration-tests.md` § CI — `app_e2e_linux` lane is a
/// no-op), the widget-test layer carries the behavioural pins for the AC2
/// "single canonical opener" and AC5 "adaptive polling with pre-pump
/// short-circuit" contracts for this opener. Without these pins, a future
/// refactor of the rail/marker selection or the post-tap fallback window
/// could silently regress at the integration-test wall-clock layer with no
/// unit-level signal.
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
    'e2eOpenCivilianPanel taps the empire rail button and detects the panel',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _CivilianRailHarness()),
      );
      expect(find.byKey(kEmpireCivilianUnitsButtonKey), findsOneWidget);
      expect(find.byKey(kCtE2ECivilianPanelRootKey), findsNothing);
      await e2eOpenCivilianPanel(
        tester,
        timeout: const Duration(seconds: 5),
      );
      expect(
        find.byKey(kCtE2ECivilianPanelRootKey),
        findsOneWidget,
        reason:
            'After tapping the keyed empire civilian rail button, the helper '
            'must detect the panel root on the next pump and return '
            '(Refs GitHub #2336 AC2 — single canonical opener).',
      );
    },
  );

  testWidgets(
    'e2eOpenCivilianPanel falls back to the first-civilian marker '
    'when the empire rail button is absent',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _CivilianMarkerOnlyHarness()),
      );
      expect(find.byKey(kEmpireCivilianUnitsButtonKey), findsNothing);
      expect(
        find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey),
        findsOneWidget,
      );
      expect(find.byKey(kCtE2ECivilianPanelRootKey), findsNothing);
      await e2eOpenCivilianPanel(
        tester,
        timeout: const Duration(seconds: 5),
      );
      expect(
        find.byKey(kCtE2ECivilianPanelRootKey),
        findsOneWidget,
        reason:
            'When the empire rail button is not in the tree, the helper must '
            'tap the first-civilian map marker as the second canonical '
            'trigger (Refs GitHub #2336 AC2 — single canonical opener).',
      );
    },
  );

  testWidgets(
    'e2eOpenCivilianPanel returns once the panel root mounts asynchronously '
    'after the rail tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _DelayedCivilianPanelHarness(
            mountAfter: Duration(milliseconds: 120),
          ),
        ),
      );
      expect(find.byKey(kCtE2ECivilianPanelRootKey), findsNothing);
      await e2eOpenCivilianPanel(
        tester,
        timeout: const Duration(seconds: 5),
      );
      expect(
        find.byKey(kCtE2ECivilianPanelRootKey),
        findsOneWidget,
        reason:
            'Adaptive polling must keep pumping past the post-tap fallback '
            'window until the panel root mounts (Refs GitHub #2336 AC5 — '
            'condition-based wait, not a fixed sleep).',
      );
    },
  );

  testWidgets(
    'e2eOpenCivilianPanel times out with TestFailure when no opener surfaces',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      Object? caught;
      try {
        await e2eOpenCivilianPanel(
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
            'first-civilian marker must surface a TestFailure rather than '
            'silently returning (Refs GitHub #2336 AC10 — no silent '
            'flakiness from timeout regressions).',
      );
    },
  );
}

/// Test harness that mounts the civilian panel root synchronously when the
/// keyed empire rail button is tapped, so the helper detects the panel on
/// the very next frame.
class _CivilianRailHarness extends StatefulWidget {
  const _CivilianRailHarness();

  @override
  State<_CivilianRailHarness> createState() => _CivilianRailHarnessState();
}

class _CivilianRailHarnessState extends State<_CivilianRailHarness> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kEmpireCivilianUnitsButtonKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Civilian'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ECivilianPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// Test harness that exposes the first-civilian marker but no empire rail
/// button, so the helper must take the marker branch as the second canonical
/// trigger.
class _CivilianMarkerOnlyHarness extends StatefulWidget {
  const _CivilianMarkerOnlyHarness();

  @override
  State<_CivilianMarkerOnlyHarness> createState() =>
      _CivilianMarkerOnlyHarnessState();
}

class _CivilianMarkerOnlyHarnessState extends State<_CivilianMarkerOnlyHarness> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kCtE2EOpenFirstCivilianMarkerPanelKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Marker'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ECivilianPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// Test harness that mounts the civilian panel root only after an in-test
/// timer fires so the helper exercises its adaptive post-tap waits before
/// returning. The keyed empire rail button drives the schedule, mirroring
/// the production-panel async harness pattern in
/// `app/test/e2e_open_production_panel_test.dart`.
class _DelayedCivilianPanelHarness extends StatefulWidget {
  const _DelayedCivilianPanelHarness({required this.mountAfter});

  final Duration mountAfter;

  @override
  State<_DelayedCivilianPanelHarness> createState() =>
      _DelayedCivilianPanelHarnessState();
}

class _DelayedCivilianPanelHarnessState
    extends State<_DelayedCivilianPanelHarness> {
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
            key: kEmpireCivilianUnitsButtonKey,
            onPressed: _handleTap,
            child: const Text('Civilian'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ECivilianPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}
