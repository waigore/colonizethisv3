// Pure-logic tests for production labour helpers (S6, Refs #2692).
// SPEC/ui/production-panel.md § Labour Controls, SPEC/game/workers-and-population.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';

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

List<ProductionLabourTierRowData> _rows({
  required Player player,
  Orders orders = const Orders(),
  bool canEdit = true,
}) {
  return buildProductionLabourRowData(
    player: player,
    currentOrders: orders,
    canEdit: canEdit,
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

  group('buildProductionLabourRowData', () {
    test('returns one row per tier in canonical order', () {
      expect(
        _rows(player: productionLabourGpWithPool())
            .map((r) => r.tier)
            .toList(),
        kProductionLabourTierOrder,
      );
    });

    test('canEdit=false disables every append, pop, and disband action', () {
      final rows = _rows(
        player: productionLabourGpWithPool(
          peasants: 5,
          masters: 3,
          treasury: 5000,
          stockpile: {
            CommodityCatalog.fabric.id: 10,
            CommodityCatalog.paper.id: 50,
          },
          techUnlocked: productionLabourFullLabourTech,
        ),
        orders: productionLabourOrdersWithRecruits([WorkerTier.master]),
        canEdit: false,
      );
      for (final row in rows) {
        expect(row.canAppend, isFalse);
        expect(row.canPop, isFalse);
        expect(row.canDisband, isFalse);
      }
    });

    test(
      'disband / pop / techUnlocked pins for peasant and trained rows',
      () {
        final peasantRow = _rows(
          player: productionLabourGpWithPool(peasants: 5),
        ).firstWhere((r) => r.tier == WorkerTier.peasant);
        expect(peasantRow.canDisband, isFalse);
        expect(peasantRow.techUnlocked, isTrue);

        final jmRow = _rows(
          player: productionLabourGpWithPool(journeymen: 2),
          orders: productionLabourOrdersWithRecruits([WorkerTier.journeyman]),
        ).firstWhere((r) => r.tier == WorkerTier.journeyman);
        expect(jmRow.queuedCount, 1);
        expect(jmRow.canPop, isTrue);
        expect(jmRow.canDisband, isTrue);

        final byTierNull = {
          for (final r in _rows(player: productionLabourGpWithPool())) r.tier: r,
        };
        for (final tier in [
          WorkerTier.apprentice,
          WorkerTier.journeyman,
          WorkerTier.master,
        ]) {
          expect(byTierNull[tier]!.techUnlocked, isFalse);
        }

        final byTierPartial = {
          for (final r in _rows(
            player: productionLabourGpWithPool(
              techUnlocked: productionLabourTrainedThroughJourneymanTech,
            ),
          ))
            r.tier: r,
        };
        expect(byTierPartial[WorkerTier.peasant]!.techUnlocked, isTrue);
        expect(byTierPartial[WorkerTier.apprentice]!.techUnlocked, isTrue);
        expect(byTierPartial[WorkerTier.journeyman]!.techUnlocked, isTrue);
        expect(byTierPartial[WorkerTier.master]!.techUnlocked, isFalse);

        final apprenticeRow = _rows(
          player: productionLabourGpWithPool(
            techUnlocked: const {
              kTechIdApprenticeWorkers: true,
              kTechIdSugarRefining: false,
            },
          ),
        ).firstWhere((r) => r.tier == WorkerTier.apprentice);
        expect(apprenticeRow.techUnlocked, isFalse);
      },
    );
  });

  group('isWorkerTierTechUnlocked', () {
    test('returns true for peasant regardless of techUnlocked', () {
      for (final tech in <Map<String, bool>?>[null, const {}]) {
        expect(
          isWorkerTierTechUnlocked(
            player: productionLabourGpWithPool(techUnlocked: tech),
            tier: WorkerTier.peasant,
          ),
          isTrue,
        );
      }
    });

    for (final case_ in <
      ({
        String name,
        Player player,
        WorkerTier tier,
        bool expected,
      })
    >[
      (
        name: 'trained tier unlocked when every required tech id is true',
        player: productionLabourGpWithPool(
          techUnlocked: const {
            kTechIdMasterArtisans: true,
            kTechIdHatProduction: true,
          },
        ),
        tier: WorkerTier.master,
        expected: true,
      ),
      (
        name: 'trained tier locked when a required tech id is missing',
        player: productionLabourGpWithPool(
          techUnlocked: const {kTechIdMasterArtisans: true},
        ),
        tier: WorkerTier.master,
        expected: false,
      ),
      (
        name: 'returns false when techUnlocked is null and tier has tech gate',
        player: productionLabourGpWithPool(),
        tier: WorkerTier.journeyman,
        expected: false,
      ),
      (
        name: 'returns false when a required tech entry is present but false',
        player: productionLabourGpWithPool(
          techUnlocked: const {
            kTechIdTrainedJourneymen: false,
            kTechIdCigarProduction: true,
          },
        ),
        tier: WorkerTier.journeyman,
        expected: false,
      ),
    ]) {
      test(case_.name, () {
        expect(
          isWorkerTierTechUnlocked(
            player: case_.player,
            tier: case_.tier,
          ),
          case_.expected,
        );
      });
    }
  });
}
