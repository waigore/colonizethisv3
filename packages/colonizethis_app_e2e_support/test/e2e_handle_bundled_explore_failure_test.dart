/// Pins the snapshot-driven failure-mode contract of
/// [e2eHandleBundledExploreFailure].
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/bundled_explore_failure_determinism_group.dart';
import 'support/bundled_explore_failure_fail_group.dart';
import 'support/bundled_explore_failure_skip_group.dart';

void main() {
  suppressLogsForTests();
  registerBundledExploreFailureSkipGroup();
  registerBundledExploreFailureFailGroup();
  registerBundledExploreFailureDeterminismGroup();
}
