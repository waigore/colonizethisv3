/// Pins the widget-tree contract of [e2eEnsureNonHomeFleetInNwAfterLoop].
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'support/ensure_non_home_fleet_nw_barrel_group.dart';
import 'support/ensure_non_home_fleet_nw_constants_group.dart';
import 'support/ensure_non_home_fleet_nw_failure_group.dart';
import 'support/ensure_non_home_fleet_nw_reach_group.dart';
import 'support/ensure_non_home_fleet_nw_sanity_group.dart';

void main() {
  suppressLogsForTests();

  setUp(() {
    ctE2eNavalPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eNavalPanelSnapshot = null;
  });

  registerEnsureNonHomeFleetConstantsGroup();
  registerEnsureNonHomeFleetReachGroup();
  registerEnsureNonHomeFleetFailureGroup();
  registerEnsureNonHomeFleetBarrelGroup();
  registerEnsureNonHomeFleetSanityGroup();
}
