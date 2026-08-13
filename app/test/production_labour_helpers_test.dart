// Pure-logic tests for production labour helpers (S6, Refs #2692).
// SPEC/ui/production-panel.md § Labour Controls, SPEC/game/workers-and-population.md.

import 'package:colonizethis_data/colonizethis_data.dart';
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

  group('queuedRecruitWorkerCountsByTier', () {
    test('returns zero counts for every tier when no orders queued', () {
      final counts = queuedRecruitWorkerCountsByTier(
        currentOrders: const Orders(),
        playerId: productionLabourTestPlayerId,
      );
      expect(counts.keys.toSet(), WorkerTier.values.toSet());
      for (final tier in WorkerTier.values) {
        expect(counts[tier], 0, reason: 'tier ${tier.id}');
      }
    });

    test('counts queued orders per tier', () {
      final orders = productionLabourOrdersWithRecruits([
        WorkerTier.peasant,
        WorkerTier.apprentice,
        WorkerTier.apprentice,
        WorkerTier.master,
      ]);
      final counts = queuedRecruitWorkerCountsByTier(
        currentOrders: orders,
        playerId: productionLabourTestPlayerId,
      );
      expect(counts[WorkerTier.peasant], 1);
      expect(counts[WorkerTier.apprentice], 2);
      expect(counts[WorkerTier.journeyman], 0);
      expect(counts[WorkerTier.master], 1);
    });

    test('ignores orders for other players', () {
      final orders = productionLabourOrdersWithRecruits(
        [WorkerTier.master],
        id: 'other_gp',
      );
      final counts = queuedRecruitWorkerCountsByTier(
        currentOrders: orders,
        playerId: productionLabourTestPlayerId,
      );
      expect(counts.values.every((v) => v == 0), isTrue);
    });
  });

  group('pendingPeasantConsumesForPlayer', () {
    test('counts non-peasant recruit orders + military builds only', () {
      final recruits = productionLabourOrdersWithRecruits([
        WorkerTier.peasant, // does not consume peasant per cost row
        WorkerTier.journeyman, // consumes peasant
        WorkerTier.master, // consumes peasant
      ]);
      final builds = productionLabourOrdersWithMilitaryBuilds(3);
      final combined = recruits.copyWith(
        buildUnitOrdersByPlayerId: builds.buildUnitOrdersByPlayerId,
      );
      expect(
        pendingPeasantConsumesForPlayer(
          currentOrders: combined,
          playerId: productionLabourTestPlayerId,
        ),
        2 + 3,
      );
    });

    test('zero when only peasant recruit orders queued', () {
      final orders = productionLabourOrdersWithRecruits([
        WorkerTier.peasant,
        WorkerTier.peasant,
      ]);
      expect(
        pendingPeasantConsumesForPlayer(
          currentOrders: orders,
          playerId: productionLabourTestPlayerId,
        ),
        0,
      );
    });
  });

  group('canAppendRecruitWorkerOrder', () {
    for (final case_ in <
      ({
        String name,
        Player player,
        WorkerTier tier,
        Orders orders,
        bool expected,
      })
    >[
      (
        name: 'peasant recruit succeeds when fabric ≥ 2',
        player: productionLabourGpWithPool(
          stockpile: {CommodityCatalog.fabric.id: 2},
        ),
        tier: WorkerTier.peasant,
        orders: const Orders(),
        expected: true,
      ),
      (
        name: 'peasant recruit fails when fabric < 2',
        player: productionLabourGpWithPool(
          stockpile: {CommodityCatalog.fabric.id: 1},
        ),
        tier: WorkerTier.peasant,
        orders: const Orders(),
        expected: false,
      ),
      (
        name: 'apprentice train fails when tech locked',
        player: productionLabourGpWithPool(
          peasants: 1,
          treasury: 200,
          stockpile: {CommodityCatalog.paper.id: 2},
        ),
        tier: WorkerTier.apprentice,
        orders: const Orders(),
        expected: false,
      ),
      (
        name: 'apprentice train succeeds with full tech + cost coverage',
        player: productionLabourGpWithPool(
          peasants: 1,
          treasury: 200,
          stockpile: {CommodityCatalog.paper.id: 2},
          techUnlocked: productionLabourApprenticeTech,
        ),
        tier: WorkerTier.apprentice,
        orders: const Orders(),
        expected: true,
      ),
      (
        name:
            'apprentice train fails when peasant ledger exhausted by pending military builds',
        player: productionLabourGpWithPool(
          peasants: 1,
          treasury: 200,
          stockpile: {CommodityCatalog.paper.id: 2},
          techUnlocked: productionLabourApprenticeTech,
        ),
        tier: WorkerTier.apprentice,
        orders: productionLabourOrdersWithMilitaryBuilds(1),
        expected: false,
      ),
      (
        name: 'second apprentice train fails when only one peasant available',
        player: productionLabourGpWithPool(
          peasants: 1,
          treasury: 1000,
          stockpile: {CommodityCatalog.paper.id: 20},
          techUnlocked: productionLabourApprenticeTech,
        ),
        tier: WorkerTier.apprentice,
        orders: productionLabourOrdersWithRecruits([WorkerTier.apprentice]),
        expected: false,
      ),
    ]) {
      test(case_.name, () {
        expect(
          _canAppend(
            player: case_.player,
            tier: case_.tier,
            orders: case_.orders,
          ),
          case_.expected,
        );
      });
    }
  });

  group('orders mutation helpers', () {
    test('append / pop LIFO + empty-list cleanup', () {
      final withPeasant =
          productionLabourOrdersWithRecruits([WorkerTier.peasant]);
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
        unchanged.recruitWorkerOrdersByPlayerId[productionLabourTestPlayerId]!
            .length,
        1,
      );

      final cleared = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: withPeasant,
        playerId: productionLabourTestPlayerId,
        tier: WorkerTier.peasant,
      );
      expect(
        cleared.recruitWorkerOrdersByPlayerId
            .containsKey(productionLabourTestPlayerId),
        isFalse,
      );
    });
  });

  group('disband helpers', () {
    test('disband journeyman increments peasants and decrements journeymen', () {
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
    });

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
          playerWithImmediateDisband(
            player: case_.player,
            tier: case_.tier,
          ),
          isNull,
        );
      });
    }

    test('gameWithImmediateDisband updates matching player or nulls missing', () {
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
    });
  });

  registerProductionLabourRowAndTechTests();
}
