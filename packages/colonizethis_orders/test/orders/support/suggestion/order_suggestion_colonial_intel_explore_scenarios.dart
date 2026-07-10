// Table-driven colonial intel explore scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_colonial_intel_explore_fixtures.dart';

void oscieRunListsSeaReachableNw() {
  final fixture = colonialIntelSeaReachableNwFixture();
  expect(
    colonialIntelExploreProvinceIdsSorted(
      view: fixture.view,
      topology: fixture.topology,
    ),
    ['newWorld|colony'],
  );
}

List<RunnableScenario> orderSuggestionColonialIntelExploreScenarios() => const [
  RunnableScenario(
    label: 'colonialIntelExploreProvinceIdsSorted lists sea-reachable NW',
    run: oscieRunListsSeaReachableNw,
  ),
];
