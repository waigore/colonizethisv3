/// Pins the snapshot-driven non-home-human-fleet-in-NW-coastal-sea contract
/// of [e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot] and the
/// two-tier adjacency contract of [e2eNwCoastalProvincesAdjacentToFleetSea].
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/coastal_nw_adjacency_group.dart';
import 'support/coastal_nw_false_group.dart';
import 'support/coastal_nw_regression_group.dart';
import 'support/coastal_nw_true_group.dart';

void main() {
  suppressLogsForTests();
  registerCoastalNwPredicateFalseGroup();
  registerCoastalNwPredicateTrueGroup();
  registerCoastalNwPredicateRegressionGroup();
  registerCoastalNwAdjacencyGroup();
}
