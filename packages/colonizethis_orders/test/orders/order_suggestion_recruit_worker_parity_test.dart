/// All-tiers ordering, peasant reservation, and engine round-trip parity
/// coverage for `suggestRecruitWorkerOrders` (Refs #2692 S7,
/// SPEC/program/order-suggestions.md § Recruit worker orders).
///
/// Smaller per-tier inclusion scenarios live in
/// `order_suggestion_recruit_worker_test.dart`. The split keeps each file
/// under the `repo.logic_test_file_size` 400 physical line limit.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_recruit_worker_test_support.dart';

void main() {
  group('suggestRecruitWorkerOrders (#2692 S7) — parity and ordering', () {
    test(
      'returns all four tiers when all techs unlocked and resources support '
      'every cost row',
      () {
        final game = recruitWorkerTestGameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 4,
                CommodityCatalog.paper.id: 50,
              },
            ),
            // Three peasants -> apprentice, journeyman, master each consume one.
            workerPool: const WorkerPool(peasants: 3),
            treasury: 5000,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
              kTechIdTrainedJourneymen: true,
              kTechIdCigarProduction: true,
              kTechIdMasterArtisans: true,
              kTechIdHatProduction: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          recruitWorkerTestViewFor(game, 'p1'),
          game,
          recruitWorkerTestTopology,
          const Orders(),
        );

        // Determinism: ordering follows WorkerTier.index ascending.
        expect(
          list.map((o) => o.targetTier).toList(),
          <WorkerTier>[
            WorkerTier.peasant,
            WorkerTier.apprentice,
            WorkerTier.journeyman,
            WorkerTier.master,
          ],
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
            reason: 'engine accepts every emitted candidate (parity)',
          );
        }
      },
    );

    test(
      'peasant reservation: pending apprentice recruit drains the only peasant '
      'so a candidate apprentice is excluded but candidate peasant remains',
      () {
        final game = recruitWorkerTestGameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 4,
                CommodityCatalog.paper.id: 50,
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

        final pending = const Orders(
          recruitWorkerOrdersByPlayerId: {
            'p1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
          },
        );

        final list = suggestRecruitWorkerOrders(
          recruitWorkerTestViewFor(game, 'p1'),
          game,
          recruitWorkerTestTopology,
          pending,
        );

        expect(
          list.any((o) => o.targetTier == WorkerTier.apprentice),
          isFalse,
          reason:
              'peasant reservation ledger: pending apprentice already '
              'consumed the only peasant',
        );
        // Peasant recruit row only needs fabric, no peasant consumed.
        expect(
          list.any((o) => o.targetTier == WorkerTier.peasant),
          isTrue,
          reason: 'peasant recruit does not consume peasants',
        );
      },
    );

    test(
      'engine round-trip parity: accept/reject decision matches '
      'addRecruitWorkerOrderWithContext for every WorkerTier in a partial '
      'tech / peasant / treasury fixture',
      () {
        // Partial: only apprentice tech; treasury below journeyman/master cost
        // rows; one peasant available; fabric for peasant.
        final game = recruitWorkerTestGameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
            stockpile: Stockpile(
              quantities: {
                CommodityCatalog.fabric.id: 4,
                CommodityCatalog.paper.id: 50,
              },
            ),
            workerPool: const WorkerPool(peasants: 1),
            treasury: 250,
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: true,
              kTechIdTrainedJourneymen: true,
              kTechIdCigarProduction: true,
              kTechIdMasterArtisans: true,
              kTechIdHatProduction: true,
            },
          ),
        );

        final list = suggestRecruitWorkerOrders(
          recruitWorkerTestViewFor(game, 'p1'),
          game,
          recruitWorkerTestTopology,
          const Orders(),
        );

        // Suggestion includes peasant + apprentice; treasury too low for
        // journeyman (500) or master (1000).
        expect(
          list.map((o) => o.targetTier).toSet(),
          {WorkerTier.peasant, WorkerTier.apprentice},
        );

        for (final tier in recruitWorkerTestAllTiers) {
          final candidate = RecruitWorkerOrder(targetTier: tier);
          final inSuggestions = list.any(
            (o) => o.targetTier == candidate.targetTier,
          );
          final engineAccepts = recruitWorkerTestEngineAccepts(
            game,
            const Orders(),
            'p1',
            candidate,
          );
          expect(
            inSuggestions,
            engineAccepts,
            reason:
                '${tier.name}: suggestion inclusion ($inSuggestions) must '
                'match engine accept ($engineAccepts) — '
                'SPEC equivalence guarantee for incremental candidate '
                'validation',
          );
        }
      },
    );

    test(
      'empty stockpile + zero treasury + zero peasants -> empty list',
      () {
        final game = recruitWorkerTestGameWith(
          player: Player(
            id: 'p1',
            displayName: 'P',
            isHuman: true,
          ),
        );

        final list = suggestRecruitWorkerOrders(
          recruitWorkerTestViewFor(game, 'p1'),
          game,
          recruitWorkerTestTopology,
          const Orders(),
        );
        expect(list, isEmpty);

        // Negative parity: every WorkerTier candidate is rejected by the
        // engine when the player has no resources.
        for (final tier in recruitWorkerTestAllTiers) {
          expect(
            recruitWorkerTestEngineAccepts(
              game,
              const Orders(),
              'p1',
              RecruitWorkerOrder(targetTier: tier),
            ),
            isFalse,
            reason:
                '${tier.name} candidate must be engine-rejected '
                '(empty player has nothing to spend)',
          );
        }
      },
    );
  });
}
