// Compact OrderEngine validateRecruitWorker assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Pins for [orderEngineValidateRecruitWorkerScenarios] rows.
enum OrderEngineValidateRecruitWorkerTarget {
  acceptsASinglePeasantRecruitWhenFabricIsAvailable,
  rejectsApprenticeTrainWhenRequiredTechIsLocked,
  recruitConsumesLastPeasantBeforeMilitaryBuild,
  civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant,
}

const _regionId = 'oldWorld';
const _provinceId = '$_regionId|P1';

final _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: _regionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game _gameWith({
  required Player player,
  List<Province> provinces = const [
    Province(id: _provinceId, regionId: _regionId, ownerId: 'p1'),
  ],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
}

void runOrderEngineValidateRecruitWorkerExpectation(
  OrderEngineValidateRecruitWorkerTarget target,
) {
  switch (target) {
    case OrderEngineValidateRecruitWorkerTarget
        .acceptsASinglePeasantRecruitWhenFabricIsAvailable:
      _acceptsASinglePeasantRecruitWhenFabricIsAvailable();
    case OrderEngineValidateRecruitWorkerTarget
        .rejectsApprenticeTrainWhenRequiredTechIsLocked:
      _rejectsApprenticeTrainWhenRequiredTechIsLocked();
    case OrderEngineValidateRecruitWorkerTarget
        .recruitConsumesLastPeasantBeforeMilitaryBuild:
      _recruitConsumesLastPeasantBeforeMilitaryBuild();
    case OrderEngineValidateRecruitWorkerTarget
        .civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant:
      _civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant();
  }
}

void _acceptsASinglePeasantRecruitWhenFabricIsAvailable() {
  final game = _gameWith(
    player: Player(
      id: 'p1',
      displayName: 'P',
      isHuman: true,
      stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 2}),
    ),
  );
  final engine = OrderEngine()
    ..addRecruitWorkerOrder(
      'p1',
      const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
    );

  final results = engine.validatePlayerOrdersWithContext(game, _topology, 'p1');

  expect(results, hasLength(1));
  expect(results.single.isAccepted, isTrue);
}

void _rejectsApprenticeTrainWhenRequiredTechIsLocked() {
  final game = _gameWith(
    player: Player(
      id: 'p1',
      displayName: 'P',
      isHuman: true,
      stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
      workerPool: const WorkerPool(peasants: 1),
      treasury: 500,
      techUnlocked: const {kTechIdApprenticeWorkers: true},
    ),
  );
  final engine = OrderEngine()
    ..addRecruitWorkerOrder(
      'p1',
      const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    );

  final results = engine.validatePlayerOrdersWithContext(game, _topology, 'p1');

  expect(results.single.isAccepted, isFalse);
  expect(results.single.reason, kRecruitWorkerTechLocked);
}

void _recruitConsumesLastPeasantBeforeMilitaryBuild() {
  final game = _gameWith(
    player: Player(
      id: 'p1',
      displayName: 'P',
      isHuman: true,
      capitalProvinceId: _provinceId,
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
  final engine = OrderEngine()
    ..addRecruitWorkerOrder(
      'p1',
      const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    )
    ..addBuildOrder(
      'p1',
      BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: true,
        spawnProvinceId: _provinceId,
      ),
    );

  final results = engine.validatePlayerOrdersWithContext(game, _topology, 'p1');

  expect(results, hasLength(2));
  expect(results[0].isAccepted, isTrue, reason: 'recruit accepted');
  expect(
    results[1].isAccepted,
    isFalse,
    reason: 'build rejected because peasant was consumed by recruit',
  );
  expect(results[1].reason, 'Insufficient workers');
}

void _civilianBuildAcceptedAfterRecruitConsumesOnlyPeasant() {
  final game = _gameWith(
    player: Player(
      id: 'p1',
      displayName: 'P',
      isHuman: true,
      capitalProvinceId: _provinceId,
      capitalTile: const CapitalTile(
        regionId: _regionId,
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
  final engine = OrderEngine()
    ..addRecruitWorkerOrder(
      'p1',
      const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    )
    ..addBuildOrder(
      'p1',
      BuildUnitOrder(
        unitType: kUnitTypeBuilder,
        isMilitary: false,
        spawnProvinceId: _provinceId,
      ),
    );

  final results = engine.validatePlayerOrdersWithContext(game, _topology, 'p1');

  expect(results, hasLength(2));
  expect(results[0].isAccepted, isTrue);
  expect(
    results[1].isAccepted,
    isTrue,
    reason: 'civilian builder does not consume peasants',
  );
}
