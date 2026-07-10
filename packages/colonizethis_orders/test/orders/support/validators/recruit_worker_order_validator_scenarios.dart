// Table-driven RecruitWorkerOrderValidator scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        kRecruitWorkerInsufficientMaterials,
        kRecruitWorkerInsufficientTreasury,
        kRecruitWorkerInsufficientWorkers,
        kRecruitWorkerTechLocked;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/recruit_worker_order_validator.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'recruit_worker_order_validator_fixtures.dart';

void rwovRunAcceptsPeasantRecruit() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 5}),
    workerPool: const WorkerPool(peasants: 3),
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final result = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
    previousRejected: false,
  );

  expect(result.isAccepted, isTrue);
  expect(validator.workers.peasants, 4);
  expect(validator.stockpile.quantityOf(CommodityCatalog.fabric.id), 3);
  expect(validator.treasury, 0);
}

void rwovRunRejectsPeasantInsufficientFabric() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 1}),
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final result = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
    previousRejected: false,
  );

  expect(result.isAccepted, isFalse);
  expect(result.reason, kRecruitWorkerInsufficientMaterials);
}

void rwovRunAcceptsApprenticeTrain() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
    workerPool: const WorkerPool(peasants: 2, apprentices: 1),
    treasury: 500,
    techUnlocked: recruitWorkerApprenticeTech,
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final result = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    previousRejected: false,
  );

  expect(result.isAccepted, isTrue);
  expect(validator.workers.peasants, 1);
  expect(validator.workers.apprentices, 2);
  expect(validator.treasury, 300);
  expect(validator.stockpile.quantityOf(CommodityCatalog.paper.id), 3);
}

void rwovRunRejectsApprenticeTechLocked() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 500,
    techUnlocked: const {kTechIdApprenticeWorkers: true},
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final result = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    previousRejected: false,
  );

  expect(result.isAccepted, isFalse);
  expect(result.reason, kRecruitWorkerTechLocked);
}

void rwovRunRejectsApprenticeNoPeasant() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
    treasury: 500,
    techUnlocked: recruitWorkerApprenticeTech,
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final result = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    previousRejected: false,
  );

  expect(result.isAccepted, isFalse);
  expect(result.reason, kRecruitWorkerInsufficientWorkers);
}

void rwovRunRejectsApprenticeInsufficientTreasury() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 100,
    techUnlocked: recruitWorkerApprenticeTech,
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final result = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    previousRejected: false,
  );

  expect(result.isAccepted, isFalse);
  expect(result.reason, kRecruitWorkerInsufficientTreasury);
}

void rwovRunAcceptsJourneymanTrain() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 6}),
    workerPool: const WorkerPool(peasants: 1, journeymen: 1),
    treasury: 600,
    techUnlocked: recruitWorkerJourneymanTech,
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final result = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
    previousRejected: false,
  );

  expect(result.isAccepted, isTrue);
  expect(validator.workers.peasants, 0);
  expect(validator.workers.journeymen, 2);
  expect(validator.treasury, 100);
  expect(validator.stockpile.quantityOf(CommodityCatalog.paper.id), 1);
}

void rwovRunAcceptsMasterTrain() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 10}),
    workerPool: const WorkerPool(peasants: 1, masters: 1),
    treasury: 1500,
    techUnlocked: recruitWorkerMasterTech,
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final result = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.master),
    previousRejected: false,
  );

  expect(result.isAccepted, isTrue);
  expect(validator.workers.peasants, 0);
  expect(validator.workers.masters, 2);
  expect(validator.treasury, 500);
  expect(validator.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
}

void rwovRunShortCircuitsPreviousRejected() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 5}),
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final result = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
    previousRejected: true,
  );

  expect(result.isAccepted, isFalse);
  expect(result.reason, 'Previous invalid');
  expect(validator.workers.peasants, 0);
}

void rwovRunSequentialApprenticeTrainsDrainPeasants() {
  final player = recruitWorkerValidatorPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 6}),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 600,
    techUnlocked: recruitWorkerApprenticeTech,
  );
  final validator = RecruitWorkerOrderValidator(player: player);

  final first = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    previousRejected: false,
  );
  final second = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    previousRejected: false,
  );
  final third = validator.validate(
    const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    previousRejected: false,
  );

  expect(first.isAccepted, isTrue);
  expect(second.isAccepted, isTrue);
  expect(third.isAccepted, isFalse);
  expect(third.reason, kRecruitWorkerInsufficientWorkers);
  expect(validator.workers.peasants, 0);
  expect(validator.workers.apprentices, 2);
  expect(validator.treasury, 200);
}

/// Canonical scenarios for RecruitWorkerOrderValidator (#2692 S4).
List<RunnableScenario> recruitWorkerOrderValidatorScenarios() => const [
  rs('accepts peasant recruit and deducts 2 fabric, adds peasant', rwovRunAcceptsPeasantRecruit, '#2692 S4'),
  rs('rejects peasant recruit when fabric is insufficient', rwovRunRejectsPeasantInsufficientFabric, '#2692 S4'),
  rs('accepts apprentice train when tech unlocked, deducts 200 ducats, 2 paper, 1 peasant; increments apprentices', rwovRunAcceptsApprenticeTrain, '#2692 S4'),
  rs('rejects apprentice train when required tech is locked', rwovRunRejectsApprenticeTechLocked, '#2692 S4'),
  rs('rejects apprentice train when no peasant is available', rwovRunRejectsApprenticeNoPeasant, '#2692 S4'),
  rs('rejects apprentice train when treasury is insufficient', rwovRunRejectsApprenticeInsufficientTreasury, '#2692 S4'),
  rs('accepts journeyman train and applies 500 ducat + 5 paper cost', rwovRunAcceptsJourneymanTrain, '#2692 S4'),
  rs('accepts master train and applies 1000 ducat + 10 paper cost', rwovRunAcceptsMasterTrain, '#2692 S4'),
  rs('short-circuits to "Previous invalid" when previousRejected is true', rwovRunShortCircuitsPreviousRejected, '#2692 S4'),
  rs('sequential apprentice trains drain peasants in submission order', rwovRunSequentialApprenticeTrainsDrainPeasants, '#2692 S4'),
];
