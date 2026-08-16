// Development assign preview fields on the candidate (Refs #4472).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/suggestion/order_suggestion_core_fixtures.dart';
import 'support/validators/work_order_cost_calculator_feedstock_bootstrap_fixtures.dart';

void main() {
  test('selectDevelopmentImproveAssignCandidate attaches level 1 cost 4+4', () {
    final s = OscDualBuilderGrainTiles();
    final player = s.player.copyWith(
      techUnlocked: const {kTechIdLandEnclosure: true},
    );
    final game = s.game().copyWith(
      players: [player],
      worldState: s.world().copyWith(
        tileState: TileMapState(improvementByTile: {s.tileA: 1, s.tileB: 1}),
      ),
    );
    final candidate = selectDevelopmentImproveAssignCandidate(
      game: game,
      playerId: OscIds.playerId,
      currentOrders: const Orders(),
      topology: s.topology(),
      tileMapByRegion: const {},
      commodityTileKeys: {s.tileA, s.tileB},
      connectedTileKeys: {s.tileA, s.tileB},
    );
    expect(candidate, isNotNull);
    expect(candidate!.targetTileKey, s.tileA);
    expect(candidate.currentImprovementLevel, 1);
    expect(candidate.nextImprovementLevel, 2);
    final preview = previewWorkOrderAffordAtTile(
      game: game,
      playerId: OscIds.playerId,
      currentOrders: const Orders(),
      workTarget: kWorkTargetBuildImprovement,
      targetTileKey: candidate.targetTileKey,
    );
    expect(candidate.materialCosts, preview.materialCosts);
    expect(candidate.materialCosts[CommodityCatalog.lumber.id], 4);
    expect(candidate.materialCosts[CommodityCatalog.castIron.id], 4);
  });

  test(
    'preview tile matches auto-pick among two grain tiles (lower level first)',
    () {
      final s = OscDualBuilderGrainTiles();
      final player = s.player.copyWith(
        techUnlocked: const {kTechIdLandEnclosure: true},
      );
      final game = s.game().copyWith(
        players: [player],
        worldState: s.world().copyWith(
          tileState: TileMapState(improvementByTile: {s.tileA: 1, s.tileB: 0}),
        ),
      );
      final candidate = selectDevelopmentImproveAssignCandidate(
        game: game,
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
        topology: s.topology(),
        tileMapByRegion: const {},
        commodityTileKeys: {s.tileA, s.tileB},
        connectedTileKeys: {s.tileA, s.tileB},
      );
      expect(candidate, isNotNull);
      expect(candidate!.targetTileKey, s.tileB);
      expect(candidate.currentImprovementLevel, 0);
    },
  );

  test(
    'enrichDevelopmentImproveAssignCandidate matches feedstock lumber-only waiver',
    () {
      final game = twoPlayerFeedstockGateGame(
        supplierStockpile: const Stockpile(quantities: {'lumber': 2}),
      );
      final candidate = enrichDevelopmentImproveAssignCandidate(
        game: game,
        playerId: feedstockBootstrapSupplierId,
        currentOrders: const Orders(),
        candidate: DevelopmentImproveAssignCandidate(
          builderUnitId: 'b1',
          targetTileKey: feedstockBootstrapIronTile,
          isCapitalConnected: true,
        ),
      );
      final preview = previewWorkOrderAffordAtTile(
        game: game,
        playerId: feedstockBootstrapSupplierId,
        currentOrders: const Orders(),
        workTarget: kWorkTargetBuildImprovement,
        targetTileKey: feedstockBootstrapIronTile,
      );
      expect(candidate.materialCosts, preview.materialCosts);
      expect(
        candidate.materialCosts.containsKey(CommodityCatalog.castIron.id),
        isFalse,
      );
      expect(candidate.materialCosts[CommodityCatalog.lumber.id], 1);
    },
  );
}
