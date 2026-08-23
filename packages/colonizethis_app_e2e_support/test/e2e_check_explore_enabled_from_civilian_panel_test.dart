/// Pins the widget-tree contract of
/// [e2eCheckExploreEnabledFromCivilianPanel]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// Widget cases live in
/// `support/e2e_check_explore_enabled_from_civilian_panel_guard_group.dart`
/// (#4598 Slice C).
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'support/e2e_check_explore_enabled_from_civilian_panel_guard_group.dart';

void main() {
  suppressLogsForTests();

  setUp(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  group('e2eCheckExploreEnabledFromCivilianPanel — default constants', () {
    test('kE2eDefaultBundledExploreRetryLoopPhase preserves the legacy '
        'inline-closure phase literal', () {
      expect(
        kE2eDefaultBundledExploreRetryLoopPhase,
        'bundled_explore_retry_loop',
        reason:
            'Pre-lift `perf.timing("bundled_explore_retry_loop", ...)` '
            'callers (and downstream `E2E_TIMING|phase=...` scrapers) '
            'must keep seeing the same canonical phase name; a silent '
            'rename would orphan every dashboard/key keyed on '
            '`bundled_explore_retry_loop` and hide Bottleneck 5 '
            'regressions.',
      );
    });

    test('kE2eDefaultFleetCivilianOpenAfterSheetClearPhase preserves the '
        'legacy fleet-scenario attribution label', () {
      expect(
        kE2eDefaultFleetCivilianOpenAfterSheetClearPhase,
        'pump_until_panels_cleared_after_close_sheet_fleet_civilian_open',
        reason:
            'The fleet-scenario override label is distinct from the '
            'generic `_civilian_open` default used by '
            '[e2eOpenCivilianPanel] callers in the full-turn scenario; '
            'collapsing the two would attribute fleet retry-loop '
            'post-sheet-close pumps to the wrong scenario in AC8 '
            'timing tables.',
      );
    });
  });

  registerCheckExploreEnabledFromCivilianPanelGuardGroup();
}
