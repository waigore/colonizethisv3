/// Pins the widget-tree contract of
/// [e2eAnyExplorerHasEnabledExploreAssignFleet]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The fleet bundled-Explore retry loop in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper
/// through the AC1 barrel alias `anyExplorerHasEnabledExploreAssignFleet`
/// inside a bounded retry window (`maxBoundedTurnRetries = 8`). A silent
/// rename / fail-open here would either:
///
///   - Stall the retry loop on the slow `maxPanelSweepSteps (16) ×
///     per-step Assign sweep` path — Bottleneck 5 in
///     `SPEC/program/e2e-integration-tests.md` § Determinism — burning
///     wall-clock the snapshot short-circuit already avoids; or
///   - Silently flip the bundled-Explore readiness verdict (always-true
///     / always-false) and mask a real production regression.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/any_explorer_assign_fleet_harness.dart';
import 'support/any_explorer_g1_group.dart';
import 'support/any_explorer_g2_group.dart';
import 'support/any_explorer_g3_group.dart';
import 'support/any_explorer_g4_group.dart';
import 'support/any_explorer_g5_group.dart';

void main() {
  suppressLogsForTests();
  registerAnyExplorerG1Group();
  registerAnyExplorerG2Group();
  registerAnyExplorerG3Group();
  registerAnyExplorerG4Group();
  registerAnyExplorerG5Group();
}
