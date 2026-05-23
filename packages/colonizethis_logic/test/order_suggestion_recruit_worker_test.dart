/// Per-tier positive / negative inclusion coverage for
/// `suggestRecruitWorkerOrders` (Refs #2692 S7,
/// SPEC/program/order-suggestions.md § Recruit worker orders).
///
/// All-tiers ordering, peasant-reservation, and engine round-trip parity
/// coverage live in `order_suggestion_recruit_worker_parity_test.dart`
/// so each file stays under the
/// `repo.logic_test_file_size` 400 physical line limit.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_recruit_worker_test_support.dart';

void main() {
  group('suggestRecruitWorkerOrders (#2692 S7) — per-tier inclusion', () {
    test(
      'returns peasant and apprentice when fabric, treasury, paper, and '
      'apprentice tech support both rows',
      () {
        // Peasant row: fabric x 2; Apprentice row: 1 peasant + 200 ducats +
        // 2 paper. Other trained tiers locked.
        final game = recruitWorkerTestGameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 4,
                CommodityCatalog.paper.id: 5,
              },
            ),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 500,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          recruitWorkerTestViewFor(game, 'p1'),
          game,
          recruitWorkerTestTopology,
          const Orders(),
        );

        expect(
          list.map((o) => o.targetTier),
          containsAllInOrder(<WorkerTier>[
            WorkerTier.peasant,
            WorkerTier.apprentice,
          ]),
        );
        expect(
          list.any((o) => o.targetTier == WorkerTier.journeyman),
          isFalse,
          reason: 'journeyman tech is locked',
        );
        expect(
          list.any((o) => o.targetTier == WorkerTier.master),
          isFalse,
          reason: 'master tech is locked',
        );

        for (final candidate in list) {
          expect(
            recruitWorkerTestEngineAccepts(
              game,
              const Orders(),
              'p1',
              candidate,
            ),
            isTrue,
            reason:
                'engine round-trip must accept emitted candidate '
                '${candidate.targetTier.name} per SPEC equivalence guarantee',
          );
        }
      },
    );

    test(
      'omits trained tiers when their required techs are locked',
      () {
        // Affordability satisfied for all trained tiers; tech gates entirely
        // missing.
        final game = recruitWorkerTestGameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 10,
                CommodityCatalog.paper.id: 50,
              },
            ),
            workerPool: const WorkerPool(peasants: 5),
            treasury: 5000,
          ),
        );

        final list = suggestRecruitWorkerOrders(
          recruitWorkerTestViewFor(game, 'p1'),
          game,
          recruitWorkerTestTopology,
          const Orders(),
        );

        expect(list.map((o) => o.targetTier).toList(), [WorkerTier.peasant]);

        // Engine must reject every locked-tier candidate (negative parity).
        for (final tier in recruitWorkerTestAllTiers.where(
          (t) => t != WorkerTier.peasant,
        )) {
          final candidate = RecruitWorkerOrder(targetTier: tier);
          expect(
            recruitWorkerTestEngineAccepts(
              game,
              const Orders(),
              'p1',
              candidate,
            ),
            isFalse,
            reason: '${tier.name} candidate rejected at the order engine '
                'because tech gate is locked',
          );
        }
      },
    );

    test(
      'omits peasant recruit when fabric is insufficient',
      () {
        final game = recruitWorkerTestGameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {CommodityCatalog.fabric.id: 1},
            ),
          ),
        );

        final list = suggestRecruitWorkerOrders(
          recruitWorkerTestViewFor(game, 'p1'),
          game,
          recruitWorkerTestTopology,
          const Orders(),
        );

        expect(
          list.any((o) => o.targetTier == WorkerTier.peasant),
          isFalse,
          reason: 'peasant row needs 2 fabric',
        );
      },
    );

    test(
      'omits apprentice recruit when treasury is below 200 ducats',
      () {
        final game = recruitWorkerTestGameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {CommodityCatalog.paper.id: 5},
            ),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 100,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          recruitWorkerTestViewFor(game, 'p1'),
          game,
          recruitWorkerTestTopology,
          const Orders(),
        );

        expect(
          list.any((o) => o.targetTier == WorkerTier.apprentice),
          isFalse,
          reason: 'apprentice row needs 200 ducats; treasury == 100',
        );
      },
    );

    test(
      'omits apprentice recruit when peasant pool is empty',
      () {
        final game = recruitWorkerTestGameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {CommodityCatalog.paper.id: 5},
            ),
            workerPool: const WorkerPool(),
            treasury: 500,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          recruitWorkerTestViewFor(game, 'p1'),
          game,
          recruitWorkerTestTopology,
          const Orders(),
        );

        expect(
          list.any((o) => o.targetTier == WorkerTier.apprentice),
          isFalse,
          reason: 'apprentice row consumes 1 peasant',
        );
      },
    );
  });
}
