// Pure-logic tests for production labour helpers (S6, Refs #2692).
// SPEC/ui/production-panel.md § Labour Controls, SPEC/game/workers-and-population.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production_labour_helpers.dart';

const _playerId = 'gp_labour_test';

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
  final militaryUnitType =
      RegimentEconomyCatalog.byId.keys.first;
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
    test('peasant recruit succeeds when fabric ≥ 2', () {
      final player = _gpWithPool(
        peasants: 0,
        stockpile: {CommodityCatalog.fabric.id: 2},
      );
      expect(
        canAppendRecruitWorkerOrder(
          player: player,
          currentOrders: const Orders(),
          candidateTier: WorkerTier.peasant,
        ),
        isTrue,
      );
    });

    test('peasant recruit fails when fabric < 2', () {
      final player = _gpWithPool(stockpile: {CommodityCatalog.fabric.id: 1});
      expect(
        canAppendRecruitWorkerOrder(
          player: player,
          currentOrders: const Orders(),
          candidateTier: WorkerTier.peasant,
        ),
        isFalse,
      );
    });

    test('apprentice train fails when tech locked', () {
      final player = _gpWithPool(
        peasants: 1,
        treasury: 200,
        stockpile: {CommodityCatalog.paper.id: 2},
      );
      expect(
        canAppendRecruitWorkerOrder(
          player: player,
          currentOrders: const Orders(),
          candidateTier: WorkerTier.apprentice,
        ),
        isFalse,
      );
    });

    test('apprentice train succeeds with full tech + cost coverage', () {
      final player = _gpWithPool(
        peasants: 1,
        treasury: 200,
        stockpile: {CommodityCatalog.paper.id: 2},
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      expect(
        canAppendRecruitWorkerOrder(
          player: player,
          currentOrders: const Orders(),
          candidateTier: WorkerTier.apprentice,
        ),
        isTrue,
      );
    });

    test('apprentice train fails when peasant ledger exhausted by pending military builds', () {
      final player = _gpWithPool(
        peasants: 1,
        treasury: 200,
        stockpile: {CommodityCatalog.paper.id: 2},
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final orders = _ordersWithMilitaryBuilds(1);
      expect(
        canAppendRecruitWorkerOrder(
          player: player,
          currentOrders: orders,
          candidateTier: WorkerTier.apprentice,
        ),
        isFalse,
      );
    });

    test('second apprentice train fails when only one peasant available', () {
      final player = _gpWithPool(
        peasants: 1,
        treasury: 1000,
        stockpile: {CommodityCatalog.paper.id: 20},
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      );
      final orders = _ordersWithRecruits([WorkerTier.apprentice]);
      expect(
        canAppendRecruitWorkerOrder(
          player: player,
          currentOrders: orders,
          candidateTier: WorkerTier.apprentice,
        ),
        isFalse,
      );
    });
  });

  group('orders mutation helpers', () {
    test('append adds one order at end and preserves prior list', () {
      final orders = _ordersWithRecruits([WorkerTier.peasant]);
      final next = ordersWithAppendedRecruitWorkerOrder(
        currentOrders: orders,
        playerId: _playerId,
        tier: WorkerTier.master,
      );
      final list = next.recruitWorkerOrdersByPlayerId[_playerId]!;
      expect(list.length, 2);
      expect(list.last.targetTier, WorkerTier.master);
      expect(list.first.targetTier, WorkerTier.peasant);
    });

    test('pop removes last matching tier (LIFO) and leaves others', () {
      final orders = _ordersWithRecruits([
        WorkerTier.apprentice,
        WorkerTier.master,
        WorkerTier.apprentice,
      ]);
      final next = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: orders,
        playerId: _playerId,
        tier: WorkerTier.apprentice,
      );
      final list = next.recruitWorkerOrdersByPlayerId[_playerId]!;
      expect(list.length, 2);
      expect(
        list.map((o) => o.targetTier).toList(),
        [WorkerTier.apprentice, WorkerTier.master],
      );
    });

    test('pop returns unchanged orders when no matching tier', () {
      final orders = _ordersWithRecruits([WorkerTier.peasant]);
      final next = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: orders,
        playerId: _playerId,
        tier: WorkerTier.master,
      );
      expect(
        next.recruitWorkerOrdersByPlayerId[_playerId]!.length,
        1,
      );
    });

    test('pop removes player entry when list becomes empty', () {
      final orders = _ordersWithRecruits([WorkerTier.peasant]);
      final next = ordersWithLastRecruitWorkerOrderRemoved(
        currentOrders: orders,
        playerId: _playerId,
        tier: WorkerTier.peasant,
      );
      expect(
        next.recruitWorkerOrdersByPlayerId.containsKey(_playerId),
        isFalse,
      );
    });
  });

  group('disband helpers', () {
    test('disband journeyman increments peasants and decrements journeymen', () {
      final player = _gpWithPool(peasants: 0, journeymen: 1, treasury: 500);
      final updated = playerWithImmediateDisband(
        player: player,
        tier: WorkerTier.journeyman,
      );
      expect(updated, isNotNull);
      expect(updated!.workerPool.peasants, 1);
      expect(updated.workerPool.journeymen, 0);
      expect(updated.treasury, 500, reason: 'disband has no treasury refund');
    });

    test('disband peasant returns null (not allowed)', () {
      final player = _gpWithPool(peasants: 3);
      final updated = playerWithImmediateDisband(
        player: player,
        tier: WorkerTier.peasant,
      );
      expect(updated, isNull);
    });

    test('disband returns null when no worker of the tier exists', () {
      final player = _gpWithPool(peasants: 1, masters: 0);
      final updated = playerWithImmediateDisband(
        player: player,
        tier: WorkerTier.master,
      );
      expect(updated, isNull);
    });

    test('gameWithImmediateDisband updates the matching player only', () {
      final p1 = _gpWithPool(masters: 1).copyWith(id: 'gp_a');
      final p2 = _gpWithPool(masters: 1).copyWith(id: 'gp_b');
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [p1, p2],
      );
      final next = gameWithImmediateDisband(
        game: game,
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
    });

    test('gameWithImmediateDisband returns null for unknown player', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      final next = gameWithImmediateDisband(
        game: game,
        playerId: 'missing',
        tier: WorkerTier.master,
      );
      expect(next, isNull);
    });
  });

  group('buildProductionLabourRowData', () {
    test('returns one row per tier in canonical order', () {
      final player = _gpWithPool();
      final rows = buildProductionLabourRowData(
        player: player,
        currentOrders: const Orders(),
        canEdit: true,
      );
      expect(
        rows.map((r) => r.tier).toList(),
        kProductionLabourTierOrder,
      );
    });

    test('canEdit=false disables every append, pop, and disband action', () {
      final player = _gpWithPool(
        peasants: 5,
        masters: 3,
        treasury: 5000,
        stockpile: {
          CommodityCatalog.fabric.id: 10,
          CommodityCatalog.paper.id: 50,
        },
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
          kTechIdTrainedJourneymen: true,
          kTechIdCigarProduction: true,
          kTechIdMasterArtisans: true,
          kTechIdHatProduction: true,
        },
      );
      final orders = _ordersWithRecruits([WorkerTier.master]);
      final rows = buildProductionLabourRowData(
        player: player,
        currentOrders: orders,
        canEdit: false,
      );
      for (final row in rows) {
        expect(row.canAppend, isFalse, reason: 'tier ${row.tier.id}');
        expect(row.canPop, isFalse, reason: 'tier ${row.tier.id}');
        expect(row.canDisband, isFalse, reason: 'tier ${row.tier.id}');
      }
    });

    test('disband is never enabled for peasant row even with peasants > 0', () {
      final player = _gpWithPool(peasants: 5);
      final rows = buildProductionLabourRowData(
        player: player,
        currentOrders: const Orders(),
        canEdit: true,
      );
      final peasantRow = rows.firstWhere((r) => r.tier == WorkerTier.peasant);
      expect(peasantRow.canDisband, isFalse);
    });

    test('canPop reflects queued count, canDisband reflects pool count', () {
      final player = _gpWithPool(journeymen: 2);
      final orders = _ordersWithRecruits([WorkerTier.journeyman]);
      final rows = buildProductionLabourRowData(
        player: player,
        currentOrders: orders,
        canEdit: true,
      );
      final jmRow = rows.firstWhere((r) => r.tier == WorkerTier.journeyman);
      expect(jmRow.queuedCount, 1);
      expect(jmRow.canPop, isTrue);
      expect(jmRow.canDisband, isTrue);
    });

    test(
      'techUnlocked is true for peasant when techUnlocked map is null or empty',
      () {
        final player = _gpWithPool();
        final rows = buildProductionLabourRowData(
          player: player,
          currentOrders: const Orders(),
          canEdit: true,
        );
        final peasantRow = rows.firstWhere(
          (r) => r.tier == WorkerTier.peasant,
        );
        expect(peasantRow.techUnlocked, isTrue);
      },
    );

    test(
      'techUnlocked is false for trained tiers when techUnlocked map is null',
      () {
        final player = _gpWithPool();
        final rows = buildProductionLabourRowData(
          player: player,
          currentOrders: const Orders(),
          canEdit: true,
        );
        for (final tier in [
          WorkerTier.apprentice,
          WorkerTier.journeyman,
          WorkerTier.master,
        ]) {
          final row = rows.firstWhere((r) => r.tier == tier);
          expect(
            row.techUnlocked,
            isFalse,
            reason: 'tier ${tier.id} should be locked without techUnlocked',
          );
        }
      },
    );

    test(
      'techUnlocked tracks per-tier required techs in WorkerActionEconomyCatalog',
      () {
        final player = _gpWithPool(
          techUnlocked: const {
            kTechIdApprenticeWorkers: true,
            kTechIdSugarRefining: true,
            kTechIdTrainedJourneymen: true,
            kTechIdCigarProduction: true,
            // Master tech gates intentionally left unlocked=false.
          },
        );
        final rows = buildProductionLabourRowData(
          player: player,
          currentOrders: const Orders(),
          canEdit: true,
        );
        final byTier = {for (final r in rows) r.tier: r};
        expect(byTier[WorkerTier.peasant]!.techUnlocked, isTrue);
        expect(byTier[WorkerTier.apprentice]!.techUnlocked, isTrue);
        expect(byTier[WorkerTier.journeyman]!.techUnlocked, isTrue);
        expect(byTier[WorkerTier.master]!.techUnlocked, isFalse);
      },
    );

    test(
      'techUnlocked is false when a required tech entry is present but false',
      () {
        final player = _gpWithPool(
          techUnlocked: const {
            kTechIdApprenticeWorkers: true,
            kTechIdSugarRefining: false,
          },
        );
        final rows = buildProductionLabourRowData(
          player: player,
          currentOrders: const Orders(),
          canEdit: true,
        );
        final apprenticeRow = rows.firstWhere(
          (r) => r.tier == WorkerTier.apprentice,
        );
        expect(apprenticeRow.techUnlocked, isFalse);
      },
    );
  });

  group('isWorkerTierTechUnlocked', () {
    test('returns true for peasant regardless of techUnlocked', () {
      expect(
        isWorkerTierTechUnlocked(
          player: _gpWithPool(),
          tier: WorkerTier.peasant,
        ),
        isTrue,
      );
      expect(
        isWorkerTierTechUnlocked(
          player: _gpWithPool(techUnlocked: const {}),
          tier: WorkerTier.peasant,
        ),
        isTrue,
      );
    });

    test(
      'returns true for a trained tier iff every required tech id is true',
      () {
        final fullyUnlocked = _gpWithPool(
          techUnlocked: const {
            kTechIdMasterArtisans: true,
            kTechIdHatProduction: true,
          },
        );
        expect(
          isWorkerTierTechUnlocked(
            player: fullyUnlocked,
            tier: WorkerTier.master,
          ),
          isTrue,
        );

        final partial = _gpWithPool(
          techUnlocked: const {kTechIdMasterArtisans: true},
        );
        expect(
          isWorkerTierTechUnlocked(player: partial, tier: WorkerTier.master),
          isFalse,
          reason: 'missing kTechIdHatProduction',
        );
      },
    );

    test(
      'returns false when techUnlocked is null and tier has tech gate',
      () {
        expect(
          isWorkerTierTechUnlocked(
            player: _gpWithPool(),
            tier: WorkerTier.journeyman,
          ),
          isFalse,
        );
      },
    );

    test(
      'returns false when a required tech entry is present but false',
      () {
        final player = _gpWithPool(
          techUnlocked: const {
            kTechIdTrainedJourneymen: false,
            kTechIdCigarProduction: true,
          },
        );
        expect(
          isWorkerTierTechUnlocked(
            player: player,
            tier: WorkerTier.journeyman,
          ),
          isFalse,
        );
      },
    );
  });
}
