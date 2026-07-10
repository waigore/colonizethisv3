// Compact RecruitWorkerOrderValidator assertions (Refs #3949 wave 3).

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

import 'recruit_worker_order_validator_fixtures.dart';

/// Pins for [recruitWorkerOrderValidatorScenarios] rows.
enum RecruitWorkerOrderValidatorTarget {
  acceptsPeasantRecruit,
  rejectsPeasantInsufficientFabric,
  acceptsApprenticeTrain,
  rejectsApprenticeTechLocked,
  rejectsApprenticeNoPeasant,
  rejectsApprenticeInsufficientTreasury,
  acceptsJourneymanTrain,
  acceptsMasterTrain,
  shortCircuitsPreviousRejected,
  sequentialApprenticeTrainsDrainPeasants,
}

void runRecruitWorkerOrderValidatorExpectation(
  RecruitWorkerOrderValidatorTarget target,
) {
  switch (target) {
    case RecruitWorkerOrderValidatorTarget.acceptsPeasantRecruit:
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

    case RecruitWorkerOrderValidatorTarget.rejectsPeasantInsufficientFabric:
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

    case RecruitWorkerOrderValidatorTarget.acceptsApprenticeTrain:
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

    case RecruitWorkerOrderValidatorTarget.rejectsApprenticeTechLocked:
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

    case RecruitWorkerOrderValidatorTarget.rejectsApprenticeNoPeasant:
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

    case RecruitWorkerOrderValidatorTarget.rejectsApprenticeInsufficientTreasury:
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

    case RecruitWorkerOrderValidatorTarget.acceptsJourneymanTrain:
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

    case RecruitWorkerOrderValidatorTarget.acceptsMasterTrain:
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

    case RecruitWorkerOrderValidatorTarget.shortCircuitsPreviousRejected:
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

    case RecruitWorkerOrderValidatorTarget.sequentialApprenticeTrainsDrainPeasants:
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
}
