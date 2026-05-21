/// Pins the contract of `e2eOpenPanelFromMarker` (Refs GitHub #2336 AC2 /
/// AC5 / AC10).
///
/// The helper is the shared full-turn opener for tile-scoped civilian/naval
/// marker panels (called twice in `new_game_full_turn_e2e_test.dart`). The
/// `e2e_test_shared_smoke_test.dart` suite already pins the **pre-pump
/// short-circuit** path (panel root already mounted) — this file covers the
/// remaining four behavioral branches that future helper edits could
/// silently regress at the integration-test wall-clock layer without any
/// unit-level signal, because `integration_test/` runs are gated behind a
/// no-op `app_e2e_linux` lane today (`SPEC/program/e2e-integration-tests.md`
/// § CI). The pin pattern mirrors `app/test/e2e_open_panel_prepump_test.dart`
/// and `app/test/e2e_wait_for_next_turn_label_advance_test.dart`.
library;

import 'dart:async';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

const Key _kTestMarkerKey = Key('e2e_open_panel_from_marker_test_marker');
const Key _kTestPanelKey = Key('e2e_open_panel_from_marker_test_panel');

/// Host that mounts a marker button and conditionally mounts a panel root
/// (sync or async) on the marker tap. An optional overlay covers the marker
/// with a hit-testable `OK` text so `e2eDismissTransientUi` can clear it
/// (matching the helper's marker-not-tappable branch).
class _MarkerHost extends StatefulWidget {
  const _MarkerHost({
    this.startWithOverlay = false,
    this.mountDelayOnTap,
    this.includeMarker = true,
  });

  /// When true, the host renders a hit-testable `OK` button covering the
  /// marker on first frame; the OK tap dismisses the overlay.
  final bool startWithOverlay;

  /// When non-null, the marker tap schedules a `Timer` of this duration
  /// before flipping `_showPanel = true`. When null the panel mounts on the
  /// same frame as the tap (`setState` in the `onPressed` callback).
  final Duration? mountDelayOnTap;

  /// When false, no marker button is rendered (used to pin the persistent
  /// absence / timeout-fail path).
  final bool includeMarker;

  @override
  State<_MarkerHost> createState() => _MarkerHostState();
}

class _MarkerHostState extends State<_MarkerHost> {
  late bool _showOverlay;
  bool _showPanel = false;
  Timer? _delayedMountTimer;

  @override
  void initState() {
    super.initState();
    _showOverlay = widget.startWithOverlay;
  }

  @override
  void dispose() {
    _delayedMountTimer?.cancel();
    super.dispose();
  }

  void _onMarkerPressed() {
    final delay = widget.mountDelayOnTap;
    if (delay == null) {
      setState(() => _showPanel = true);
      return;
    }
    _delayedMountTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _showPanel = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.includeMarker)
          Center(
            child: TextButton(
              key: _kTestMarkerKey,
              onPressed: _onMarkerPressed,
              child: const Text('marker'),
            ),
          ),
        if (_showPanel)
          KeyedSubtree(
            key: _kTestPanelKey,
            child: const ColoredBox(color: Color(0xFF112233)),
          ),
        if (_showOverlay)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xCC000000),
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => _showOverlay = false),
                  child: const Text('OK'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> _pumpHost(
  WidgetTester tester, {
  bool startWithOverlay = false,
  Duration? mountDelayOnTap,
  bool includeMarker = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _MarkerHost(
          startWithOverlay: startWithOverlay,
          mountDelayOnTap: mountDelayOnTap,
          includeMarker: includeMarker,
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'mounts panel root on the same frame as the marker tap (sync path)',
    (WidgetTester tester) async {
      await _pumpHost(tester);
      final panelRoot = find.byKey(_kTestPanelKey);
      expect(
        panelRoot.evaluate(),
        isEmpty,
        reason: 'Sanity check: panel root must start absent so the helper '
            'reaches the marker-tap branch instead of short-circuiting.',
      );

      final sw = Stopwatch()..start();
      await e2eOpenPanelFromMarker(
        tester,
        markerButton: find.byKey(_kTestMarkerKey),
        panelRoot: panelRoot,
        timeout: const Duration(seconds: 5),
      );

      expect(panelRoot.evaluate(), isNotEmpty);
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 500)),
        reason: 'Sync mount must be detected via the immediate post-tap '
            'check (no `e2ePumpUntilConditionOrIdle` ramp), keeping wall '
            'clock well under the 5s timeout cap (#2336 AC2).',
      );
    },
  );

  testWidgets(
    'observes async panel mount via adaptive pump after marker tap',
    (WidgetTester tester) async {
      await _pumpHost(
        tester,
        mountDelayOnTap: const Duration(milliseconds: 120),
      );
      final panelRoot = find.byKey(_kTestPanelKey);

      final sw = Stopwatch()..start();
      await e2eOpenPanelFromMarker(
        tester,
        markerButton: find.byKey(_kTestMarkerKey),
        panelRoot: panelRoot,
        timeout: const Duration(seconds: 5),
      );

      expect(
        panelRoot.evaluate(),
        isNotEmpty,
        reason: 'Helper must keep pumping past the immediate post-tap '
            'fallback window via `e2ePumpUntilConditionOrIdle` until the '
            'delayed setState lands (#2336 AC5).',
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(seconds: 5)),
        reason: 'Adaptive pump must observe the 120ms delayed mount well '
            'before the 5s budget; reaching the timeout would indicate the '
            'condition-based wait missed the flip.',
      );
    },
  );

  testWidgets(
    'dismisses transient OK overlay covering the marker before tapping',
    (WidgetTester tester) async {
      await _pumpHost(tester, startWithOverlay: true);
      final marker = find.byKey(_kTestMarkerKey);
      final panelRoot = find.byKey(_kTestPanelKey);
      expect(
        marker.hitTestable().evaluate(),
        isEmpty,
        reason: 'Sanity check: marker must be obscured by the overlay so '
            'the helper enters the `e2eDismissTransientUi` branch instead '
            'of tapping immediately.',
      );
      expect(panelRoot.evaluate(), isEmpty);

      await e2eOpenPanelFromMarker(
        tester,
        markerButton: marker,
        panelRoot: panelRoot,
        timeout: const Duration(seconds: 5),
      );

      expect(
        find.text('OK').evaluate(),
        isEmpty,
        reason: 'Dismiss path must have removed the overlay so future '
            'iterations stop matching the OK text.',
      );
      expect(
        panelRoot.evaluate(),
        isNotEmpty,
        reason: 'Once the overlay is dismissed the marker becomes tappable '
            'and the panel must mount (#2336 AC2).',
      );
    },
  );

  testWidgets(
    'fails with TestFailure when marker never appears within the timeout',
    (WidgetTester tester) async {
      await _pumpHost(tester, includeMarker: false);
      final marker = find.byKey(_kTestMarkerKey);
      final panelRoot = find.byKey(_kTestPanelKey);
      expect(
        marker.evaluate(),
        isEmpty,
        reason: 'Sanity check: marker must never enter the tree so the '
            'helper exhausts its budget on the marker-not-tappable branch.',
      );

      Object? caught;
      try {
        await e2eOpenPanelFromMarker(
          tester,
          markerButton: marker,
          panelRoot: panelRoot,
          timeout: const Duration(milliseconds: 300),
        );
      } catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<TestFailure>(),
        reason: 'Persistent marker/panel absence must surface as a '
            'TestFailure rather than silently returning, so real opener '
            'regressions are not swallowed (#2336 AC10).',
      );
      expect(panelRoot.evaluate(), isEmpty);
    },
  );
}
