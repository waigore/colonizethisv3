// Scenario run tear-offs for debug console workers (Refs #3949 wave 3).

import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

void dcwRunWorkerTierIdsCanonicalAndLexicographicallySorted() {
  expect(
    debugConsoleSupportedWorkerTierIdsSorted,
    orderedEquals(<String>['apprentices', 'journeymen', 'masters', 'peasants']),
  );
  expect(debugConsoleSupportedWorkerTierIds, hasLength(4));
  expect(debugConsoleSupportedWorkerTierIds, contains('peasants'));
  expect(debugConsoleSupportedWorkerTierIds, contains('apprentices'));
  expect(debugConsoleSupportedWorkerTierIds, contains('journeymen'));
  expect(debugConsoleSupportedWorkerTierIds, contains('masters'));
}
