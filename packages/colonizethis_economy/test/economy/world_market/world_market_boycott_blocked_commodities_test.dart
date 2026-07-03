// Table-driven SPEC-AC tests for `boycottedColonySellableCommodityIds` (Refs #3856).
// SPEC/ai/treasury-planner.md § Boycott-aware bid suppression (#3758 S7/R12).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  late final Map<String, TileMapResult> tileMaps;
  late final MapTopology topology;

  setUpAll(() {
    tileMaps = tileMapsForBoycottColonyTribeTest();
    topology = topologyForBoycottColonyTribeTest();
  });

  group('boycottedColonySellableCommodityIds (Refs #3758 S7/R12)', () {
    for (final scenario in boycottBlockedCommoditiesScenarios()) {
      test(scenario.label, () {
        runBoycottBlockedCommoditiesScenario(
          scenario: scenario,
          defaultTileMaps: tileMaps,
          defaultTopology: topology,
        );
      });
    }
  });
}
