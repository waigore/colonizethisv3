/// Pins the branch waterfall of `e2eWaitForMapHudAfterNewGameStart`.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/wait_map_hud_branch_group.dart';
import 'support/wait_map_hud_timeout_group.dart';
import 'support/wait_map_hud_perf_group.dart';
import 'support/wait_map_hud_perf_opt_out_group.dart';

void main() {
  suppressLogsForTests();
  registerWaitMapHudBranchGroup();
  registerWaitMapHudTimeoutGroup();
  registerWaitMapHudPerfGroup();
  registerWaitMapHudPerfOptOutGroup();
}
