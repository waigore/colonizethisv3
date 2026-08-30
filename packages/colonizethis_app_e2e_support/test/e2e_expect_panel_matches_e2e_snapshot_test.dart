/// Pins the AC1-barrel forwarding contract for the four per-panel
/// snapshot-text matchers lifted in this slice.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/expect_panel_e2e_snapshot_barrel_group.dart';
import 'support/expect_panel_e2e_snapshot_constants_group.dart';
import 'support/expect_panel_e2e_snapshot_null_group.dart';

void main() {
  suppressLogsForTests();
  registerExpectPanelE2eSnapshotConstantsGroup();
  registerExpectPanelE2eSnapshotNullGroup();
  registerExpectPanelE2eSnapshotBarrelGroup();
}
