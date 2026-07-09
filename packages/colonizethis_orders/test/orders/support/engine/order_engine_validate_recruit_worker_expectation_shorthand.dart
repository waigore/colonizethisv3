// Compact order-engine validateRecruitWorker expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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
}) =>
    Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(provinces: provinces),
        newWorld: const RegionData(),
      ),
      players: [player],
    );

OrderEngine vrwEngine() => OrderEngine();

List<OrderValidationResult> vrwValidate(Game game, OrderEngine engine) =>
    engine.validatePlayerOrdersWithContext(game, vrwTopology, 'p1');

void vrwAddRecruit(OrderEngine engine, WorkerTier tier) {
  engine.addRecruitWorkerOrder(
    'p1',
    RecruitWorkerOrder(targetTier: tier),
  );
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

void vrwExpectSingleAccepted(List<OrderValidationResult> results) {
  expect(results, hasLength(1));
  expect(results.single.isAccepted, isTrue);
}

void vrwExpectSingleRejected(
  List<OrderValidationResult> results, {
  String? reason,
}) {
  expect(results.single.isAccepted, isFalse);
  if (reason != null) {
    expect(results.single.reason, reason);
  }
}

Player vrwPlayer({
  Stockpile? stockpile,
  WorkerPool workerPool = const WorkerPool(),
  int treasury = 0,
  String? capitalProvinceId,
  CapitalTile? capitalTile,
  Map<String, bool> techUnlocked = const {},
}) =>
    Player(
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

void vrwExpectPeasantRecruitAccepted() {
  final game = vrwGameWith(
    player: vrwPlayer(
      stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 2}),
    ),
  );
  final engine = vrwEngine();
  vrwAddRecruit(engine, WorkerTier.peasant);
  vrwExpectSingleAccepted(vrwValidate(game, engine));
}

void vrwExpectApprenticeTrainRejectedTechLocked() {
  final game = vrwGameWith(
    player: vrwPlayer(
      stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
      workerPool: const WorkerPool(peasants: 1),
      treasury: 500,
      techUnlocked: const {kTechIdApprenticeWorkers: true},
    ),
  );
  final engine = vrwEngine();
  vrwAddRecruit(engine, WorkerTier.apprentice);
  vrwExpectSingleRejected(
    vrwValidate(game, engine),
    reason: kRecruitWorkerTechLocked,
  );
}

void vrwExpectRecruitConsumesPeasantBeforeMilitaryBuild() {
  final game = vrwGameWith(
    player: vrwPlayer(
      capitalProvinceId: vrwProvinceId,
      stockpile: Stockpile(
        quantities: {
          CommodityCatalog.paper.id: 50,
          CommodityCatalog.steel.id: 50,
          CommodityCatalog.fabric.id: 50,
        },
      ),
      workerPool: const WorkerPool(peasants: 1),
      treasury: 5000,
      techUnlocked: const {
        kTechIdApprenticeWorkers: true,
        kTechIdSugarRefining: true,
      },
    ),
  );
  final engine = vrwEngine();
  vrwAddRecruit(engine, WorkerTier.apprentice);
  vrwAddBuild(engine, 'peasant_levies', isMilitary: true);
  final results = vrwValidate(game, engine);
  expect(results, hasLength(2));
  expect(results[0].isAccepted, isTrue, reason: 'recruit accepted');
  expect(
    results[1].isAccepted,
    isFalse,
    reason: 'build rejected because peasant was consumed by recruit',
  );
  expect(results[1].reason, 'Insufficient workers');
}

void vrwExpectRecruitThenCivilianBuildAccepted() {
  final game = vrwGameWith(
    player: vrwPlayer(
      capitalProvinceId: vrwProvinceId,
      capitalTile: const CapitalTile(
        regionId: vrwRegionId,
        provinceId: 'P1',
        x: 0,
        y: 0,
      ),
      stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 20}),
      workerPool: const WorkerPool(peasants: 1),
      treasury: 5000,
      techUnlocked: const {
        kTechIdApprenticeWorkers: true,
        kTechIdSugarRefining: true,
      },
    ),
  );
  final engine = vrwEngine();
  vrwAddRecruit(engine, WorkerTier.apprentice);
  vrwAddBuild(engine, kUnitTypeBuilder, isMilitary: false);
  final results = vrwValidate(game, engine);
  expect(results, hasLength(2));
  expect(results[0].isAccepted, isTrue);
  expect(
    results[1].isAccepted,
    isTrue,
    reason: 'civilian builder does not consume peasants',
  );
}
