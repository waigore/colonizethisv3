// Table-driven debug console worker scenarios (Refs #3949 wave 3).

import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

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

List<RunnableScenario> debugConsoleWorkersScenarios() => const [
  RunnableScenario(
    label: 'debug worker tier ids are canonical and lexicographically sorted',
    run: dcwRunWorkerTierIdsCanonicalAndLexicographicallySorted,
  ),
];
