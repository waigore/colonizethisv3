// Lock-recovery affordability guard fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const buildLockRecoveryTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

/// Game with one owned province whose owner has zero treasury, fabric, and
/// peasants but **no riches** in the stockpile.
Game brokeNoRichesGame({required bool isHuman}) {
  final base = TestFixtures.gameWithSingleOwnedProvince(
    ownerPlayerId: 'p1',
    provinceId: 'oldWorld|p1',
    treasury: 0,
    isHuman: isHuman,
  );
  final player = base.players.single;
  return base.copyWith(
    players: [
      player.copyWith(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.fabric.id, 5),
        workerPool: const WorkerPool(peasants: 5),
      ),
    ],
  );
}

Game brokeWithRichesGame() {
  final base = TestFixtures.gameWithSingleOwnedProvince(
    ownerPlayerId: 'p1',
    provinceId: 'oldWorld|p1',
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

bool isRegimentBuild(Object order) {
  if (order is! BuildUnitOrder) return false;
  return RegimentEconomyCatalog.byId.containsKey(order.unitType);
}
