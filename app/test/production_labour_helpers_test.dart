// Pure-logic tests for production labour helpers (S6, Refs #2692).
// SPEC/ui/production-panel.md § Labour Controls, SPEC/game/workers-and-population.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';

const _playerId = 'gp_labour_test';

const _apprenticeTech = <String, bool>{
  kTechIdApprenticeWorkers: true,
  kTechIdSugarRefining: true,
};

const _trainedThroughJourneymanTech = <String, bool>{
  ..._apprenticeTech,
  kTechIdTrainedJourneymen: true,
  kTechIdCigarProduction: true,
};

const _fullLabourTech = <String, bool>{
  ..._trainedThroughJourneymanTech,
  kTechIdMasterArtisans: true,
  kTechIdHatProduction: true,
};

Player _gpWithPool({
  int peasants = 0,
  int apprentices = 0,
  int journeymen = 0,
  int masters = 0,
  int treasury = 0,
  Map<String, int> stockpile = const {},
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: _playerId,
    displayName: 'Labour test GP',
    isHuman: true,
    workerPool: WorkerPool(
      peasants: peasants,
      apprentices: apprentices,
      journeymen: journeymen,
      masters: masters,
    ),
    stockpile: Stockpile(quantities: Map<String, int>.from(stockpile)),
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

Orders _ordersWithRecruits(List<WorkerTier> tiers, {String id = _playerId}) {
  if (tiers.isEmpty) return const Orders();
  return Orders(
    recruitWorkerOrdersByPlayerId: {
      id: [for (final t in tiers) RecruitWorkerOrder(targetTier: t)],
    },
  );
}

Orders _ordersWithMilitaryBuilds(int count, {String id = _playerId}) {
  if (count <= 0) return const Orders();
  // Pick a regiment unit type from the catalog so peasant-cost classification is real.
  final militaryUnitType = RegimentEconomyCatalog.byId.keys.first;
  return Orders(
    buildUnitOrdersByPlayerId: {
      id: [
        for (var i = 0; i < count; i++)
          BuildUnitOrder(
            unitType: militaryUnitType,
            isMilitary: true,
            spawnProvinceId: 'province_x',
          ),
      ],
    },
  );
}

Game _emptyGame({List<Player> players = const []}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}

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
        playerId: _playerId,
      );
      expect(counts.keys.toSet(), WorkerTier.values.toSet());
      for (final tier in WorkerTier.values) {
        expect(counts[tier], 0, reason: 'tier ${tier.id}');
      }
    });

    test('counts queued orders per tier', () {
      final orders = _ordersWithRecruits([
        WorkerTier.peasant,
        WorkerTier.apprentice,
        WorkerTier.apprentice,
        WorkerTier.master,
      ]);
      final counts = queuedRecruitWorkerCountsByTier(
        currentOrders: orders,
        playerId: _playerId,
      );
      expect(counts[WorkerTier.peasant], 1);
      expect(counts[WorkerTier.apprentice], 2);
      expect(counts[WorkerTier.journeyman], 0);
      expect(counts[WorkerTier.master], 1);
    });

    test('ignores orders for other players', () {
      final orders = _ordersWithRecruits([WorkerTier.master], id: 'other_gp');
      final counts = queuedRecruitWorkerCountsByTier(
        currentOrders: orders,
        playerId: _playerId,
      );
      expect(counts.values.every((v) => v == 0), isTrue);
    });
  });

  group('pendingPeasantConsumesForPlayer', () {
    test('counts non-peasant recruit orders + military builds only', () {
      final recruits = _ordersWithRecruits([
        WorkerTier.peasant, // does not consume peasant per cost row
        WorkerTier.journeyman, // consumes peasant
        WorkerTier.master, // consumes peasant
      ]);
      final builds = _ordersWithMilitaryBuilds(3);
      final combined = recruits.copyWith(
        buildUnitOrdersByPlayerId: builds.buildUnitOrdersByPlayerId,
      );
      expect(
        pendingPeasantConsumesForPlayer(
          currentOrders: combined,
          playerId: _playerId,
        ),
        2 + 3,
      );
    });

    test('zero when only peasant recruit orders queued', () {
      final orders = _ordersWithRecruits([WorkerTier.peasant, WorkerTier.peasant]);
      expect(
        pendingPeasantConsumesForPlayer(
          currentOrders: orders,
          playerId: _playerId,
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
        player: _gpWithPool(stockpile: {CommodityCatalog.fabric.id: 2}),
        tier: WorkerTier.peasant,
        orders: const Orders(),
        expected: true,
      ),
      (
        name: 'peasant recruit fails when fabric < 2',
        player: _gpWithPool(stockpile: {CommodityCatalog.fabric.id: 1}),
        tier: WorkerTier.peasant,
        orders: const Orders(),
        expected: false,
      ),
      (
        name: 'apprentice train fails when tech locked',
        player: _gpWithPool(
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
        player: _gpWithPool(
          peasants: 1,
          treasury: 200,
          stockpile: {CommodityCatalog.paper.id: 2},
          techUnlocked: _apprenticeTech,
        ),
        tier: WorkerTier.apprentice,
        orders: const Orders(),
        expected: true,
      ),
      (
        name:
            'apprentice train fails when peasant ledger exhausted by pending military builds',
        player: _gpWithPool(
          peasants: 1,
          treasury: 200,
          stockpile: {CommodityCatalog.paper.id: 2},
          techUnlocked: _apprenticeTech,
        ),
        tier: WorkerTier.apprentice,
        orders: _ordersWithMilitaryBuilds(1),
        expected: false,
      ),
      (
        name: 'second apprentice train fails when only one peasant available',
        player: _gpWithPool(
          peasants: 1,
          treasury: 1000,
          stockpile: {CommodityCatalog.paper.id: 20},
          techUnlocked: _apprenticeTech,
        ),
        tier: WorkerTier.apprentice,
        orders: _ordersWithRecruits([WorkerTier.apprentice]),
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
      final withPeasant = _ordersWithRecruits([WorkerTier.peasant]);
      final appended = ordersWithAppendedRecruitWorkerOrder(
        currentOrders: withPeasant,
        playerId: _playerId,
        tier: WorkerTier.master,
      );
      final appendedList = appended.recruitWorkerOrdersByPlayerId[_playerId]!;
      expect(appendedList.length, 2);
      expect(appendedList.last.targetTier, WorkerTier.master);
      expect(appendedList.first.targetTier, WorkerTier.peasant);

      final stacked = _ordersWithRecruits([
        WorkerTier.apprentice,
        WorkerTier.master,
        WorkerTier.apprentice,
      ]);
      final popped = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: stacked,
        playerId: _playerId,
        tier: WorkerTier.apprentice,
      );
      expect(
        popped.recruitWorkerOrdersByPlayerId[_playerId]!
            .map((o) => o.targetTier)
            .toList(),
        [WorkerTier.apprentice, WorkerTier.master],
      );

      final unchanged = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: withPeasant,
        playerId: _playerId,
        tier: WorkerTier.master,
      );
      expect(unchanged.recruitWorkerOrdersByPlayerId[_playerId]!.length, 1);

      final cleared = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: withPeasant,
        playerId: _playerId,
        tier: WorkerTier.peasant,
      );
      expect(
        cleared.recruitWorkerOrdersByPlayerId.containsKey(_playerId),
        isFalse,
      );
    });
  });

  group('disband helpers', () {
    test('disband journeyman increments peasants and decrements journeymen', () {
      final updated = playerWithImmediateDisband(
        player: _gpWithPool(peasants: 0, journeymen: 1, treasury: 500),
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
        player: _gpWithPool(peasants: 3),
        tier: WorkerTier.peasant,
      ),
      (
        name: 'disband returns null when no worker of the tier exists',
        player: _gpWithPool(peasants: 1, masters: 0),
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
        game: _emptyGame(
          players: [
            _gpWithPool(masters: 1).copyWith(id: 'gp_a'),
            _gpWithPool(masters: 1).copyWith(id: 'gp_b'),
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
          game: _emptyGame(),
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
        _rows(player: _gpWithPool()).map((r) => r.tier).toList(),
        kProductionLabourTierOrder,
      );
    });

    test('canEdit=false disables every append, pop, and disband action', () {
      final rows = _rows(
        player: _gpWithPool(
          peasants: 5,
          masters: 3,
          treasury: 5000,
          stockpile: {
            CommodityCatalog.fabric.id: 10,
            CommodityCatalog.paper.id: 50,
          },
          techUnlocked: _fullLabourTech,
        ),
        orders: _ordersWithRecruits([WorkerTier.master]),
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
          player: _gpWithPool(peasants: 5),
        ).firstWhere((r) => r.tier == WorkerTier.peasant);
        expect(peasantRow.canDisband, isFalse);
        expect(peasantRow.techUnlocked, isTrue);

        final jmRow = _rows(
          player: _gpWithPool(journeymen: 2),
          orders: _ordersWithRecruits([WorkerTier.journeyman]),
        ).firstWhere((r) => r.tier == WorkerTier.journeyman);
        expect(jmRow.queuedCount, 1);
        expect(jmRow.canPop, isTrue);
        expect(jmRow.canDisband, isTrue);

        final byTierNull = {
          for (final r in _rows(player: _gpWithPool())) r.tier: r,
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
            player: _gpWithPool(techUnlocked: _trainedThroughJourneymanTech),
          ))
            r.tier: r,
        };
        expect(byTierPartial[WorkerTier.peasant]!.techUnlocked, isTrue);
        expect(byTierPartial[WorkerTier.apprentice]!.techUnlocked, isTrue);
        expect(byTierPartial[WorkerTier.journeyman]!.techUnlocked, isTrue);
        expect(byTierPartial[WorkerTier.master]!.techUnlocked, isFalse);

        final apprenticeRow = _rows(
          player: _gpWithPool(
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
            player: _gpWithPool(techUnlocked: tech),
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
        player: _gpWithPool(
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
        player: _gpWithPool(
          techUnlocked: const {kTechIdMasterArtisans: true},
        ),
        tier: WorkerTier.master,
        expected: false,
      ),
      (
        name: 'returns false when techUnlocked is null and tier has tech gate',
        player: _gpWithPool(),
        tier: WorkerTier.journeyman,
        expected: false,
      ),
      (
        name: 'returns false when a required tech entry is present but false',
        player: _gpWithPool(
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
