// Compact order-engine validateRecruitWorker expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const vrwRegionId = 'oldWorld';
const vrwProvinceId = '$vrwRegionId|P1';

final vrwTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: vrwRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game vrwGameWith({
  required Player player,
  List<Province> provinces = const [
    Province(id: vrwProvinceId, regionId: vrwRegionId, ownerId: 'p1'),
  ],
}) => ordersOwRegionGame(
  id: 'g',
  players: [player],
  oldWorld: RegionData(provinces: provinces),
);

OrderEngine vrwEngine() => OrderEngine();

List<OrderValidationResult> vrwValidate(Game game, OrderEngine engine) =>
    engine.validatePlayerOrdersWithContext(game, vrwTopology, 'p1');

void vrwAddRecruit(OrderEngine engine, WorkerTier tier) {
  engine.addRecruitWorkerOrder('p1', RecruitWorkerOrder(targetTier: tier));
}

void vrwAddBuild(
  OrderEngine engine,
  String unitType, {
  required bool isMilitary,
}) {
  engine.addBuildOrder(
    'p1',
    BuildUnitOrder(
      unitType: unitType,
      isMilitary: isMilitary,
      spawnProvinceId: vrwProvinceId,
    ),
  );
}

Player vrwPlayer({
  Stockpile? stockpile,
  WorkerPool workerPool = const WorkerPool(),
  int treasury = 0,
  String? capitalProvinceId,
  CapitalTile? capitalTile,
  Map<String, bool> techUnlocked = const {},
}) => Player(
  id: 'p1',
  displayName: 'P',
  isHuman: true,
  stockpile: stockpile ?? Stockpile.empty,
  workerPool: workerPool,
  treasury: treasury,
  capitalProvinceId: capitalProvinceId,
  capitalTile: capitalTile,
  techUnlocked: techUnlocked,
);
