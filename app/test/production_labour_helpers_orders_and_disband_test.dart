// Pure-logic tests for production labour helpers (S6, Refs #2692).
// SPEC/ui/production-panel.md § Labour Controls, SPEC/game/workers-and-population.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';

import 'production_labour_helpers_extended_test_support.dart';
import 'production_labour_test_fixtures.dart';

bool _canAppend({
  required Player player,
  required WorkerTier tier,
  Orders orders = const Orders(),
}) {
  return canAppendRecruitWorkerOrder(
    player: player,
    currentOrders: orders,
    candidateTier: tier,
  );
}

void main() {
  suppressLogsForTests();

  group('orders mutation helpers', () {
    test('append / pop LIFO + empty-list cleanup', () {
      final withPeasant = productionLabourOrdersWithRecruits([
        WorkerTier.peasant,
      ]);
      final appended = ordersWithAppendedRecruitWorkerOrder(
        currentOrders: withPeasant,
        playerId: productionLabourTestPlayerId,
        tier: WorkerTier.master,
      );
      final appendedList =
          appended.recruitWorkerOrdersByPlayerId[productionLabourTestPlayerId]!;
      expect(appendedList.length, 2);
      expect(appendedList.last.targetTier, WorkerTier.master);
      expect(appendedList.first.targetTier, WorkerTier.peasant);

      final stacked = productionLabourOrdersWithRecruits([
        WorkerTier.apprentice,
        WorkerTier.master,
        WorkerTier.apprentice,
      ]);
      final popped = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: stacked,
        playerId: productionLabourTestPlayerId,
        tier: WorkerTier.apprentice,
      );
      expect(
        popped.recruitWorkerOrdersByPlayerId[productionLabourTestPlayerId]!
            .map((o) => o.targetTier)
            .toList(),
        [WorkerTier.apprentice, WorkerTier.master],
      );

      final unchanged = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: withPeasant,
        playerId: productionLabourTestPlayerId,
        tier: WorkerTier.master,
      );
      expect(
        unchanged
            .recruitWorkerOrdersByPlayerId[productionLabourTestPlayerId]!
            .length,
        1,
      );

      final cleared = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: withPeasant,
        playerId: productionLabourTestPlayerId,
        tier: WorkerTier.peasant,
      );
      expect(
        cleared.recruitWorkerOrdersByPlayerId.containsKey(
          productionLabourTestPlayerId,
        ),
        isFalse,
      );
    });
  });

  group('disband helpers', () {
    test(
      'disband journeyman increments peasants and decrements journeymen',
      () {
        final updated = playerWithImmediateDisband(
          player: productionLabourGpWithPool(
            peasants: 0,
            journeymen: 1,
            treasury: 500,
          ),
          tier: WorkerTier.journeyman,
        );
        expect(updated, isNotNull);
        expect(updated!.workerPool.peasants, 1);
        expect(updated.workerPool.journeymen, 0);
        expect(updated.treasury, 500);
      },
    );

    for (final case_ in <({String name, Player player, WorkerTier tier})>[
      (
        name: 'disband peasant returns null (not allowed)',
        player: productionLabourGpWithPool(peasants: 3),
        tier: WorkerTier.peasant,
      ),
      (
        name: 'disband returns null when no worker of the tier exists',
        player: productionLabourGpWithPool(peasants: 1, masters: 0),
        tier: WorkerTier.master,
      ),
    ]) {
      test(case_.name, () {
        expect(
          playerWithImmediateDisband(player: case_.player, tier: case_.tier),
          isNull,
        );
      });
    }

    test(
      'gameWithImmediateDisband updates matching player or nulls missing',
      () {
        final next = gameWithImmediateDisband(
          game: productionLabourEmptyGame(
            players: [
              productionLabourGpWithPool(masters: 1).copyWith(id: 'gp_a'),
              productionLabourGpWithPool(masters: 1).copyWith(id: 'gp_b'),
            ],
          ),
          playerId: 'gp_a',
          tier: WorkerTier.master,
        );
        expect(next, isNotNull);
        final updatedA = next!.players.firstWhere((p) => p.id == 'gp_a');
        final unchangedB = next.players.firstWhere((p) => p.id == 'gp_b');
        expect(updatedA.workerPool.masters, 0);
        expect(updatedA.workerPool.peasants, 1);
        expect(unchangedB.workerPool.masters, 1);
        expect(unchangedB.workerPool.peasants, 0);

        expect(
          gameWithImmediateDisband(
            game: productionLabourEmptyGame(),
            playerId: 'missing',
            tier: WorkerTier.master,
          ),
          isNull,
        );
      },
    );
  });

  group('recruitWorkerAppendCheck refusal reasons', () {
    test('insufficient materials names fabric for peasant', () {
      final check = recruitWorkerAppendCheck(
        player: productionLabourGpWithPool(
          stockpile: {CommodityCatalog.fabric.id: 1},
        ),
        currentOrders: const Orders(),
        candidateTier: WorkerTier.peasant,
      );
      expect(check.canAppend, isFalse);
      expect(check.reason, kRecruitWorkerInsufficientMaterials);
      expect(check.insufficientMaterialIds, {CommodityCatalog.fabric.id});
    });

    test('insufficient treasury for apprentice when tech and peasants ok', () {
      final check = recruitWorkerAppendCheck(
        player: productionLabourGpWithPool(
          peasants: 1,
          treasury: 50,
          stockpile: {CommodityCatalog.paper.id: 10},
          techUnlocked: productionLabourApprenticeTech,
        ),
        currentOrders: const Orders(),
        candidateTier: WorkerTier.apprentice,
      );
      expect(check.canAppend, isFalse);
      expect(check.reason, kRecruitWorkerInsufficientTreasury);
    });

    test('insufficient workers when military reservation consumes peasant', () {
      final check = recruitWorkerAppendCheck(
        player: productionLabourGpWithPool(
          peasants: 1,
          treasury: 200,
          stockpile: {CommodityCatalog.paper.id: 2},
          techUnlocked: productionLabourApprenticeTech,
        ),
        currentOrders: productionLabourOrdersWithMilitaryBuilds(1),
        candidateTier: WorkerTier.apprentice,
      );
      expect(check.canAppend, isFalse);
      expect(check.reason, kRecruitWorkerInsufficientWorkers);
    });
  });
}
