// Consolidated boycott and lock-recovery runners (Refs #3939 phase 3 slice 2).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
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

  group('computeLockRecoveryMinorAutoBids', () {
    for (final scenario in lockRecoveryMinorBidsScenarios()) {
      test(scenario.label, () {
        final bids = computeLockRecoveryMinorAutoBids(
          game: scenario.game,
          worldMarketState: lockRecoveryGrainMarket(),
        );
        scenario.verify(bids);
      });
    }
  });
}
