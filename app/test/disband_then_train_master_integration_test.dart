// AC #3 (#2692) cross-layer integration: in the Orders phase the player
// disbands one trained worker (immediate) and queues a `RecruitWorkerOrder`
// targeting a tier requiring a peasant. When `applyBuildAndWorkOrders` runs
// at end-of-turn, the queued recruit must observe the freshly demoted peasant
// and apply the cost row from `SPEC/game/workers-and-population.md` § Recruiting,
// Training, and Disbanding.
//
// This pin closes the loop between the immediate disband helper
// (`gameWithImmediateDisband`, app) and the worker pool sub-phase resolver
// (`applyBuildAndWorkOrders`, colonizethis_logic). Each side is covered in
// isolation by `production_labour_helpers_test.dart` and
// `orders_application_worker_pool_phase_test.dart`; this test ensures the
// composed flow matches AC #3 end-to-end.
//
// Refs #2692 S9.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production_labour_helpers.dart';

const _playerId = 'gp_ac3';

Player _gp({
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
    displayName: 'AC#3 GP',
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

Game _gameWith(Player player) {
  return Game(
    id: 'g_ac3',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
}

Map<String, bool> _withMasterTech() => const {
  kTechIdMasterArtisans: true,
  kTechIdHatProduction: true,
};

void main() {
  suppressLogsForTests();

  group('AC #3 (#2692): disband trained tier then queue master recruit '
      '(integration: gameWithImmediateDisband + applyBuildAndWorkOrders)', () {
    test('disband journeyman immediately (peasants +1 / journeymen -1) and '
        'after turn resolve the queued master recruit applies the cost row '
        '(masters +1 / peasants -1 / treasury -1000 / paper -10)', () {
      final start = _gameWith(
        _gp(
          peasants: 0,
          journeymen: 1,
          treasury: 1000,
          stockpile: {CommodityCatalog.paper.id: 10},
          techUnlocked: _withMasterTech(),
        ),
      );

      final afterDisband = gameWithImmediateDisband(
        game: start,
        playerId: _playerId,
        tier: WorkerTier.journeyman,
      );
      expect(afterDisband, isNotNull, reason: 'disband must succeed');
      final post = afterDisband!.players.single;
      expect(post.workerPool.peasants, 1);
      expect(post.workerPool.journeymen, 0);
      expect(
        post.treasury,
        1000,
        reason: 'disband does not refund treasury (SPEC § Disband)',
      );

      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          _playerId: const [RecruitWorkerOrder(targetTier: WorkerTier.master)],
        },
      );

      final resolved = applyBuildAndWorkOrders(afterDisband, orders);

      final p = resolved.players.single;
      expect(p.workerPool.peasants, 0, reason: 'one peasant consumed');
      expect(p.workerPool.journeymen, 0);
      expect(p.workerPool.masters, 1);
      expect(
        p.treasury,
        0,
        reason: '1000 ducats deducted per SPEC § Recruiting cost table',
      );
      expect(
        p.stockpile.quantityOf(CommodityCatalog.paper.id),
        0,
        reason: '10 paper deducted per SPEC § Recruiting cost table',
      );
    });

    test(
      'mirror with apprentice tier: disband apprentice then resolve master '
      'recruit yields masters +1 / peasants -1 / treasury -1000 / paper -10',
      () {
        final start = _gameWith(
          _gp(
            peasants: 0,
            apprentices: 1,
            treasury: 1000,
            stockpile: {CommodityCatalog.paper.id: 10},
            techUnlocked: _withMasterTech(),
          ),
        );

        final afterDisband = gameWithImmediateDisband(
          game: start,
          playerId: _playerId,
          tier: WorkerTier.apprentice,
        );
        expect(afterDisband, isNotNull);
        expect(afterDisband!.players.single.workerPool.peasants, 1);
        expect(afterDisband.players.single.workerPool.apprentices, 0);

        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            _playerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.master),
            ],
          },
        );

        final resolved = applyBuildAndWorkOrders(afterDisband, orders);

        final p = resolved.players.single;
        expect(p.workerPool.peasants, 0);
        expect(p.workerPool.apprentices, 0);
        expect(p.workerPool.masters, 1);
        expect(p.treasury, 0);
        expect(p.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
      },
    );

    test('master recruit queued WITHOUT a prior disband is silently skipped '
        'when no peasant is available (resolver enforces peasant ledger; '
        'AC #4 mirror)', () {
      // Negative complement: same starting GP as the journeyman scenario,
      // but the player forgets to disband first. The master order must
      // be skipped (no partial mutation) because no peasant exists to be
      // consumed even though treasury/paper/tech are satisfied.
      final start = _gameWith(
        _gp(
          peasants: 0,
          journeymen: 1,
          treasury: 1000,
          stockpile: {CommodityCatalog.paper.id: 10},
          techUnlocked: _withMasterTech(),
        ),
      );

      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          _playerId: const [RecruitWorkerOrder(targetTier: WorkerTier.master)],
        },
      );

      final resolved = applyBuildAndWorkOrders(start, orders);

      final p = resolved.players.single;
      expect(p.workerPool.peasants, 0);
      expect(p.workerPool.journeymen, 1, reason: 'journeyman untouched');
      expect(p.workerPool.masters, 0, reason: 'master order skipped');
      expect(p.treasury, 1000, reason: 'no treasury deducted');
      expect(
        p.stockpile.quantityOf(CommodityCatalog.paper.id),
        10,
        reason: 'no paper deducted',
      );
    });

    test('disband then queue master with master_artisans missing -> recruit '
        'silently skipped (tech gate AC #3 negative pin)', () {
      final start = _gameWith(
        _gp(
          peasants: 0,
          journeymen: 1,
          treasury: 1000,
          stockpile: {CommodityCatalog.paper.id: 10},
          techUnlocked: const {
            // master_artisans intentionally absent
            kTechIdHatProduction: true,
          },
        ),
      );

      final afterDisband = gameWithImmediateDisband(
        game: start,
        playerId: _playerId,
        tier: WorkerTier.journeyman,
      );
      expect(afterDisband, isNotNull);

      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          _playerId: const [RecruitWorkerOrder(targetTier: WorkerTier.master)],
        },
      );

      final resolved = applyBuildAndWorkOrders(afterDisband!, orders);

      final p = resolved.players.single;
      expect(
        p.workerPool.peasants,
        1,
        reason: 'disbanded peasant retained; master order tech-locked',
      );
      expect(p.workerPool.masters, 0);
      expect(p.treasury, 1000);
      expect(p.stockpile.quantityOf(CommodityCatalog.paper.id), 10);
    });
  });
}
