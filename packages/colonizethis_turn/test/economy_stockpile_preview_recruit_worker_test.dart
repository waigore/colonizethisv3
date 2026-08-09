import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_stockpile_preview_recruit_worker_cases.dart';
import 'support/economy_stockpile_preview_test_support.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Pending [RecruitWorkerOrder] costs feed the production-panel economy
/// preview (#2692 S5; SPEC/program/order-projections.md § Production panel
/// stockpile preview phases, SPEC/ui/production-panel.md § Net Changes,
/// SPEC/game/workers-and-population.md § Recruiting, Training, and Disbanding).
void main() {
  suppressLogsForTests();

  group('previewStockpileNetDeltaByCommodityForPlayer recruit worker '
      '(#2692 S5)', () {
    test('peasant recruit deducts fabric in pending build costs phase', () {
      final player = economyPreviewRecruitWorkerPlayer(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.fabric.id, 3),
      );
      final game = TestFixtures.singlePlayerGame(player);
      final currentOrders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
        },
      );

      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );
      final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );

      expect(delta[CommodityCatalog.fabric.id], -2);
      expect(
        phases[EconomyPreviewStockpilePhase
            .pendingBuildCosts]![CommodityCatalog.fabric.id],
        -2,
      );
      expectPhaseDeltasSumToNet(
        game: game,
        playerId: 'p1',
        currentOrders: currentOrders,
      );
    });

    test('apprentice recruit deducts paper and projects worker tier on the '
        'preview clone (treasury also debited)', () {
      final player = economyPreviewRecruitWorkerPlayer(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.paper.id, 4),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 500,
        techUnlocked: economyPreviewRecruitApprenticeTechUnlocked,
      );
      final game = TestFixtures.singlePlayerGame(player);
      final currentOrders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
      );

      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );
      final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );

      expect(delta[CommodityCatalog.paper.id], -2);
      expect(
        phases[EconomyPreviewStockpilePhase
            .pendingBuildCosts]![CommodityCatalog.paper.id],
        -2,
      );

      final preview = applyEconomyPhasesForPreview(
        game: game,
        topology: const MapTopology(),
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );
      final updated = preview.playerById('p1')!;
      expect(updated.treasury, 300);
      expect(updated.workerPool.peasants, 0);
      expect(updated.workerPool.apprentices, 1);

      expectPhaseDeltasSumToNet(
        game: game,
        playerId: 'p1',
        currentOrders: currentOrders,
      );
    });

    test('unaffordable recruit (no peasant) contributes no preview deltas', () {
      final player = economyPreviewRecruitWorkerPlayer(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.paper.id, 10),
        workerPool: const WorkerPool(peasants: 0),
        treasury: 1000,
        techUnlocked: economyPreviewRecruitApprenticeTechUnlocked,
      );
      final game = TestFixtures.singlePlayerGame(player);
      final currentOrders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
      );

      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );
      final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );

      expect(delta, isEmpty);
      expect(
        phases[EconomyPreviewStockpilePhase.pendingBuildCosts],
        isEmpty,
      );

      final preview = applyEconomyPhasesForPreview(
        game: game,
        topology: const MapTopology(),
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );
      final updated = preview.playerById('p1')!;
      expect(updated.treasury, 1000);
      expect(updated.workerPool.peasants, 0);
      expect(updated.workerPool.apprentices, 0);
      expect(updated.stockpile.quantityOf(CommodityCatalog.paper.id), 10);
    });

    test('tech-locked recruit (apprentice tier without unlocks) contributes '
        'no preview deltas', () {
      final player = economyPreviewRecruitWorkerPlayer(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.paper.id, 10),
        workerPool: const WorkerPool(peasants: 5),
        treasury: 1000,
      );
      final game = TestFixtures.singlePlayerGame(player);
      final currentOrders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
      );

      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );

      expect(delta, isEmpty);

      final preview = applyEconomyPhasesForPreview(
        game: game,
        topology: const MapTopology(),
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );
      final updated = preview.playerById('p1')!;
      expect(updated.treasury, 1000);
      expect(updated.workerPool.peasants, 5);
      expect(updated.workerPool.apprentices, 0);
    });

    test('recruit-worker order is applied before BuildUnitOrder in preview '
        '(matches live Build / work resolver order)', () {
      const ownedProvinceId = 'oldWorld|p1';
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        capitalProvinceId: ownedProvinceId,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.fabric.id, 5)
            .applyDelta(CommodityCatalog.paper.id, 5),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 5000,
        techUnlocked: economyPreviewRecruitApprenticeTechUnlocked,
      );
      final game = TestFixtures.minimalGame(
        players: [player],
        oldWorld: RegionData(
          provinces: const [
            Province(
              id: ownedProvinceId,
              regionId: 'oldWorld',
              ownerId: 'p1',
            ),
          ],
        ),
      );

      final currentOrders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
        buildUnitOrdersByPlayerId: {
          'p1': const [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary: true,
              spawnProvinceId: ownedProvinceId,
            ),
          ],
        },
      );

      final preview = applyEconomyPhasesForPreview(
        game: game,
        topology: const MapTopology(),
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );
      final updated = preview.playerById('p1')!;

      expect(updated.workerPool.peasants, 0);
      expect(updated.workerPool.apprentices, 1);
      expect(updated.treasury, 5000 - 200);
      expect(updated.stockpile.quantityOf(CommodityCatalog.paper.id), 3);
      expect(updated.stockpile.quantityOf(CommodityCatalog.fabric.id), 5);
    });

    test('preview parity: sequential apprentice + peasant recruits deduct '
        'correctly when the second cannot afford', () {
      final player = economyPreviewRecruitWorkerPlayer(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.paper.id, 2),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 250,
        techUnlocked: economyPreviewRecruitApprenticeTechUnlocked,
      );
      final game = TestFixtures.singlePlayerGame(player);
      final currentOrders = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': const [
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ],
        },
      );

      final preview = applyEconomyPhasesForPreview(
        game: game,
        topology: const MapTopology(),
        inputs: economyPreviewInputs(currentOrders: currentOrders),
      );
      final updated = preview.playerById('p1')!;
      expect(updated.workerPool.peasants, 0);
      expect(updated.workerPool.apprentices, 1);
      expect(updated.stockpile.quantityOf(CommodityCatalog.paper.id), 0);
      expect(updated.treasury, 50);
    });
  });
}
