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
/// Refs GitHub #2336 (AC2 — shared helpers used by E2E tests; AC5 — adaptive
/// polling with pre-pump short-circuit; AC10 — no silent flakiness from
/// timeout regressions).
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eOpenProductionPanel short-circuits when panel root already mounted',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyedSubtree(
              key: kCtE2EProductionPanelRootKey,
              child: Container(width: 200, height: 200, color: Colors.green),
            ),
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
      await tester.pumpWidget(
        const MaterialApp(home: _ProductionRailHarness()),
      );
      expect(find.byKey(kEmpireProductionButtonKey), findsOneWidget);
      expect(find.byKey(kCtE2EProductionPanelRootKey), findsNothing);
      await e2eOpenProductionPanel(
        tester,
        timeout: const Duration(seconds: 5),
      );
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
        const MaterialApp(
          home: _DelayedProductionPanelHarness(
            mountAfter: Duration(milliseconds: 120),
          ),
        ),
      );
      expect(find.byKey(kCtE2EProductionPanelRootKey), findsNothing);
      await e2eOpenProductionPanel(
        tester,
        timeout: const Duration(seconds: 5),
      );
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
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
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
}

/// Test harness that mounts the panel root synchronously on the rail tap so
/// the helper detects it on the very next frame.
class _ProductionRailHarness extends StatefulWidget {
  const _ProductionRailHarness();

  @override
  State<_ProductionRailHarness> createState() => _ProductionRailHarnessState();
}

class _ProductionRailHarnessState extends State<_ProductionRailHarness> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kEmpireProductionButtonKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Production'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2EProductionPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// Test harness that mounts the panel root only after an in-test [Timer] fires
/// so the helper exercises its adaptive post-tap waits before returning.
class _DelayedProductionPanelHarness extends StatefulWidget {
  const _DelayedProductionPanelHarness({required this.mountAfter});

  final Duration mountAfter;

  @override
  State<_DelayedProductionPanelHarness> createState() =>
      _DelayedProductionPanelHarnessState();
}

class _DelayedProductionPanelHarnessState
    extends State<_DelayedProductionPanelHarness> {
  bool _panelOpen = false;
  bool _scheduled = false;

  void _handleTap() {
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    Future<void>.delayed(widget.mountAfter, () {
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
            key: kEmpireProductionButtonKey,
            onPressed: _handleTap,
            child: const Text('Production'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2EProductionPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}
