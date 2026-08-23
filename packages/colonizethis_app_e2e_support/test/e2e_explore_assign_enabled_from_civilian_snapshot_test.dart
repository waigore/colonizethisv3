/// Pins the snapshot-driven Explore-Assign contract of
/// [e2eExploreAssignEnabledFromCivilianSnapshot]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// Behavioural axes live in `support/explore_assign_snapshot_*_group.dart`
/// (Refs #4598 Slice C densify).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/explore_assign_snapshot_false_group.dart';
import 'support/explore_assign_snapshot_true_group.dart';

void main() {
  suppressLogsForTests();
  registerExploreAssignSnapshotNullAndFalseGroups();
  registerExploreAssignSnapshotTrueAndGuardGroups();
}
