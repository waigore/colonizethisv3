/// Pins the snapshot-driven NW-fogged-or-better contract of
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// The bundled-explore readiness loop
/// (`_awaitNwCoastalOrVisibleLandForBundledExploreE2e` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`) and the
/// fleet-reach test's final guard
/// (`new_game_fleet_reaches_new_world_e2e_test.dart` line ~365) depend on
/// this predicate to short-circuit once the human player has *any* NW
/// province tile fogged-or-better. A silent rename / fail-open would
/// either stall the bundled-explore readiness loop for the full 35-turn
/// cap (Bottleneck 4 in `SPEC/program/e2e-integration-tests.md`
/// § Determinism) or convert the strict bundled-explore assertion into a
/// silent skip and mask a real Explore-assign regression — both directly
/// inflate the wall-clock cap #2336 is reducing.
///
/// The integration suite cannot validate this directly today
/// (the `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin (Refs GitHub #2336 AC1 / AC2).
///
/// Behavioural axes live in `support/fogged_or_better_*_group.dart`
/// (#4344 Slice C densify).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/fogged_or_better_false_group.dart';
import 'support/fogged_or_better_regression_group.dart';
import 'support/fogged_or_better_true_group.dart';

void main() {
  suppressLogsForTests();
  registerFoggedOrBetterFalseGroup();
  registerFoggedOrBetterTrueGroup();
  registerFoggedOrBetterRegressionGroup();
}
