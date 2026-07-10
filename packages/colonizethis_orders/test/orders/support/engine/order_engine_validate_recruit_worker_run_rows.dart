// Scenario run tear-offs for OrderEngine validateRecruitWorker (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_validate_recruit_worker_expectation_shorthand.dart';

void vrwRunAcceptsSinglePeasantRecruitWhenFabricAvailable() {
  final game = vrwGameWith(
    player: vrwPlayer(
      stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 2}),
    ),
  );
  final engine = vrwEngine();
  vrwAddRecruit(engine, WorkerTier.peasant);
  final results = vrwValidate(game, engine);
  expect(results, hasLength(1));
  expect(results.single.isAccepted, isTrue);
}

void vrwRunRejectsApprenticeTrainWhenRequiredTechLocked() {
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
  final results = vrwValidate(game, engine);
  expect(results.single.isAccepted, isFalse);
  expect(results.single.reason, kRecruitWorkerTechLocked);
}

void vrwRunRecruitConsumesLastPeasantBeforeMilitaryBuild() {
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

void vrwRunCivilianBuildAcceptedAfterRecruitConsumesOnlyPeasant() {
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
