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

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/e2e_open_panel_from_marker_host.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'mounts panel root on the same frame as the marker tap (sync path)',
    (WidgetTester tester) async {
      await pumpOpenPanelFromMarkerHost(tester);
      final panelRoot = find.byKey(kOpenPanelFromMarkerTestPanelKey);
      expect(
        panelRoot.evaluate(),
        isEmpty,
        reason:
            'Sanity check: panel root must start absent so the helper '
            'reaches the marker-tap branch instead of short-circuiting.',
      );

      final sw = Stopwatch()..start();
      await e2eOpenPanelFromMarker(
        tester,
        markerButton: find.byKey(kOpenPanelFromMarkerTestMarkerKey),
        panelRoot: panelRoot,
        timeout: const Duration(seconds: 5),
      );

      expect(panelRoot.evaluate(), isNotEmpty);
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 500)),
        reason:
            'Sync mount must be detected via the immediate post-tap '
            'check (no `e2ePumpUntilConditionOrIdle` ramp), keeping wall '
            'clock well under the 5s timeout cap (#2336 AC2).',
      );
    },
  );

  testWidgets('observes async panel mount via adaptive pump after marker tap', (
    WidgetTester tester,
  ) async {
    await pumpOpenPanelFromMarkerHost(
      tester,
      mountDelayOnTap: const Duration(milliseconds: 120),
    );
    final panelRoot = find.byKey(kOpenPanelFromMarkerTestPanelKey);

    final sw = Stopwatch()..start();
    await e2eOpenPanelFromMarker(
      tester,
      markerButton: find.byKey(kOpenPanelFromMarkerTestMarkerKey),
      panelRoot: panelRoot,
      timeout: const Duration(seconds: 5),
    );

    expect(
      panelRoot.evaluate(),
      isNotEmpty,
      reason:
          'Helper must keep pumping past the immediate post-tap '
          'fallback window via `e2ePumpUntilConditionOrIdle` until the '
          'delayed setState lands (#2336 AC5).',
    );
    expect(
      sw.elapsed,
      lessThan(const Duration(seconds: 5)),
      reason:
          'Adaptive pump must observe the 120ms delayed mount well '
          'before the 5s budget; reaching the timeout would indicate the '
          'condition-based wait missed the flip.',
    );
  });

  testWidgets(
    'dismisses transient OK overlay covering the marker before tapping',
    (WidgetTester tester) async {
      await pumpOpenPanelFromMarkerHost(tester, startWithOverlay: true);
      final marker = find.byKey(kOpenPanelFromMarkerTestMarkerKey);
      final panelRoot = find.byKey(kOpenPanelFromMarkerTestPanelKey);
      expect(
        marker.hitTestable().evaluate(),
        isEmpty,
        reason:
            'Sanity check: marker must be obscured by the overlay so '
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
        reason:
            'Dismiss path must have removed the overlay so future '
            'iterations stop matching the OK text.',
      );
      expect(
        panelRoot.evaluate(),
        isNotEmpty,
        reason:
            'Once the overlay is dismissed the marker becomes tappable '
            'and the panel must mount (#2336 AC2).',
      );
    },
  );

  testWidgets(
    'fails with TestFailure when marker never appears within the timeout',
    (WidgetTester tester) async {
      await pumpOpenPanelFromMarkerHost(tester, includeMarker: false);
      final marker = find.byKey(kOpenPanelFromMarkerTestMarkerKey);
      final panelRoot = find.byKey(kOpenPanelFromMarkerTestPanelKey);
      expect(
        marker.evaluate(),
        isEmpty,
        reason:
            'Sanity check: marker must never enter the tree so the '
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
        reason:
            'Persistent marker/panel absence must surface as a '
            'TestFailure rather than silently returning, so real opener '
            'regressions are not swallowed (#2336 AC10).',
      );
      expect(panelRoot.evaluate(), isEmpty);
    },
  );
}
