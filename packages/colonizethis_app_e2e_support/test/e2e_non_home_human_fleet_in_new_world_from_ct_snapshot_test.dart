/// Pins the snapshot-driven fleet-in-NW contract of
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// Behavioural axes live in `support/non_home_human_fleet_snapshot_*_group.dart`
/// (Refs #4598 Slice C densify).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/non_home_human_fleet_snapshot_false_group.dart';
import 'support/non_home_human_fleet_snapshot_true_group.dart';

void main() {
  suppressLogsForTests();
  registerNonHomeHumanFleetSnapshotFalseGroup();
  registerNonHomeHumanFleetSnapshotTrueGroup();
  registerNonHomeHumanFleetSnapshotRegressionGroup();
}
