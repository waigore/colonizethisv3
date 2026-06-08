import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/economy/worker_action_cost.dart';
import 'package:colonizethis_orders/src/orders/validators/recruit_worker_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('RecruitWorkerOrderValidator (#2692 S4)', () {
    /// SPEC: workers-and-population.md § Recruit Peasant — peasant row has no
    /// tech and only costs 2 fabric, no peasant consumed.
    test('accepts peasant recruit and deducts 2 fabric, adds peasant', () {
      final player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 5}),
        workerPool: const WorkerPool(peasants: 3),
        treasury: 0,
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
    });

    test('rejects peasant recruit when fabric is insufficient', () {
      final player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 1}),
      );
      final validator = RecruitWorkerOrderValidator(player: player);

      final result = validator.validate(
        const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
        previousRejected: false,
      );

      expect(result.isAccepted, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientMaterials);
    });

    /// SPEC: workers-and-population.md § Train Apprentice — both tech ids
    /// required, 200 ducats, 2 paper, consumes 1 peasant.
    test('accepts apprentice train when tech unlocked, deducts 200 ducats, '
        '2 paper, 1 peasant; increments apprentices', () {
      final player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
        workerPool: const WorkerPool(peasants: 2, apprentices: 1),
        treasury: 500,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
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
    });

    test('rejects apprentice train when required tech is locked', () {
      final player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
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
    });

    test('rejects apprentice train when no peasant is available', () {
      final player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
        treasury: 500,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final validator = RecruitWorkerOrderValidator(player: player);

      final result = validator.validate(
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        previousRejected: false,
      );

      expect(result.isAccepted, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientWorkers);
    });

    test('rejects apprentice train when treasury is insufficient', () {
      final player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 100,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final validator = RecruitWorkerOrderValidator(player: player);

      final result = validator.validate(
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        previousRejected: false,
      );

      expect(result.isAccepted, isFalse);
      expect(result.reason, kRecruitWorkerInsufficientTreasury);
    });

    /// SPEC: workers-and-population.md § Train Journeyman cost row.
    test('accepts journeyman train and applies 500 ducat + 5 paper cost', () {
      final player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 6}),
        workerPool: const WorkerPool(peasants: 1, journeymen: 1),
        treasury: 600,
        techUnlocked: const {
          kTechIdTrainedJourneymen: true,
          kTechIdCigarProduction: true,
        },
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
    });

    /// SPEC: workers-and-population.md § Train Master cost row.
    test('accepts master train and applies 1000 ducat + 10 paper cost', () {
      final player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 10}),
        workerPool: const WorkerPool(peasants: 1, masters: 1),
        treasury: 1500,
        techUnlocked: const {
          kTechIdMasterArtisans: true,
          kTechIdHatProduction: true,
        },
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
    });

    test(
      'short-circuits to "Previous invalid" when previousRejected is true',
      () {
        final player = Player(
          id: 'p1',
          displayName: 'P',
          isHuman: true,
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
      },
    );

    test('sequential apprentice trains drain peasants in submission order', () {
      final player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 6}),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 600,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
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
    });
  });
}
