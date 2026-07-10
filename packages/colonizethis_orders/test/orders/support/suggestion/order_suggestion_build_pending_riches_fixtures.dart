// Shared fixtures for pending-riches build suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const orderSuggestionBuildPendingRichesProvinceId = 'oldWorld|p1';
const orderSuggestionBuildPendingRichesPlayerId = 'p1';

const orderSuggestionBuildPendingRichesTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: orderSuggestionBuildPendingRichesProvinceId,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

Game orderSuggestionBuildPendingRichesGame() {
  final base = TestFixtures.gameWithSingleOwnedProvince(
    ownerPlayerId: orderSuggestionBuildPendingRichesPlayerId,
    provinceId: orderSuggestionBuildPendingRichesProvinceId,
    treasury: 0,
    isHuman: false,
  );
  final player = base.players.single;
  return base.copyWith(
    players: [
      player.copyWith(
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.spices.id, 50)
            .applyDelta(CommodityCatalog.fabric.id, 5),
        workerPool: const WorkerPool(peasants: 5),
      ),
    ],
  );
}
