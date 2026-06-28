import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'economy_stockpile_preview_test_support.dart';
import 'test_fixtures.dart';

/// Stockpile preview for production panel. SPEC/ui/production-panel.md,
/// SPEC/game/stockpiles-and-production.md.
void main() {
  suppressLogsForTests();

  group('previewStockpilePhaseDeltasByCommodityForPlayer', () {
    test('unknown player yields empty maps per phase', () {
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile(),
      );
      final game = singlePlayerGame(player);
      final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'missing',
      );
      for (final m in phases.values) {
        expect(m, isEmpty);
      }
    });
  });

  group('previewStockpileNetDeltaByCommodityForPlayer', () {
    test(
      'pending build_improvement work orders deduct in pending build phase',
      () {
        const tileKey = 'oldWorld|ow|p1|0|0';
        final tileState = const TileMapState().setImprovement(tileKey, 0);
        final stockpile = const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 10)
            .applyDelta(CommodityCatalog.castIron.id, 10);
        final game = TestFixtures.singlePlayerWorkPreviewGame(
          playerStockpile: stockpile,
          units: [
            Unit(
              id: 'b1',
              type: kUnitTypeBuilder,
              ownerId: 'p1',
              locationProvinceId: 'ow|p1',
              tileKey: tileKey,
            ),
          ],
          tileState: tileState,
        );
        final currentOrders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'b1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: tileKey,
              ),
            ],
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
        expect(delta[CommodityCatalog.lumber.id], -1);
        expect(delta[CommodityCatalog.castIron.id], -1);
        expect(
          phases[EconomyPreviewStockpilePhase
              .pendingBuildCosts]![CommodityCatalog.lumber.id],
          -1,
        );
        expect(
          phases[EconomyPreviewStockpilePhase
              .pendingBuildCosts]![CommodityCatalog.castIron.id],
          -1,
        );
        expectPhaseDeltasSumToNet(
          game: game,
          playerId: 'p1',
          currentOrders: currentOrders,
        );
      },
    );

    test(
      'build_improvement preview uses improvement level for material cost',
      () {
        const tileKey = 'oldWorld|ow|p1|0|0';
        final tileState = const TileMapState().setImprovement(tileKey, 1);
        final stockpile = const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 10)
            .applyDelta(CommodityCatalog.castIron.id, 10);
        final game = TestFixtures.singlePlayerWorkPreviewGame(
          playerStockpile: stockpile,
          units: [
            Unit(
              id: 'b1',
              type: kUnitTypeBuilder,
              ownerId: 'p1',
              locationProvinceId: 'ow|p1',
              tileKey: tileKey,
            ),
          ],
          tileState: tileState,
        );
        final currentOrders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'b1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final delta = previewStockpileNetDeltaByCommodityForPlayer(
          game: game,
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: currentOrders),
        );
        expect(delta[CommodityCatalog.lumber.id], -4);
        expect(delta[CommodityCatalog.castIron.id], -4);
      },
    );

    test('build_improvement preview skips busy unit or unaffordable cost', () {
      const tileKey = 'oldWorld|ow|p1|0|0';
      final tileState = const TileMapState();
      final busyUnit = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: CurrentWork(
          workTarget: kWorkTargetBuildImprovement,
          tileKey: tileKey,
          totalTurns: 2,
          remainingTurns: 2,
        ),
      );
      final poorPlayer = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile(),
      );
      final gameBusy = TestFixtures.minimalGame(
        id: 't',
        players: [poorPlayer],
        oldWorld: RegionData(units: [busyUnit]),
        tileState: tileState,
      );
      final ordersBusy = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      expect(
        previewStockpileNetDeltaByCommodityForPlayer(
          game: gameBusy,
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: ordersBusy),
        ),
        isEmpty,
      );

      final playerLowStock = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 1)
            .applyDelta(CommodityCatalog.castIron.id, 1),
      );
      final gamePoorCost = TestFixtures.minimalGame(
        id: 't2',
        players: [playerLowStock],
        oldWorld: RegionData(
          units: [
            Unit(
              id: 'b2',
              type: kUnitTypeBuilder,
              ownerId: 'p1',
              locationProvinceId: 'ow|p1',
              tileKey: tileKey,
            ),
          ],
        ),
        tileState: const TileMapState().setImprovement(tileKey, 1),
      );
      final ordersPoorCost = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'b2',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      expect(
        previewStockpileNetDeltaByCommodityForPlayer(
          game: gamePoorCost,
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: ordersPoorCost),
        ),
        isEmpty,
      );
    });

    test('build_improvement preview skips disallowed unit type', () {
      const tileKey = 'oldWorld|ow|p1|0|0';
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 10)
            .applyDelta(CommodityCatalog.castIron.id, 10),
      );
      final game = TestFixtures.minimalGame(
        id: 't',
        players: [player],
        oldWorld: RegionData(
          units: [
            Unit(
              id: 'u1',
              type: 'peasant_levies',
              ownerId: 'p1',
              locationProvinceId: 'ow|p1',
            ),
          ],
        ),
      );
      final currentOrders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      expect(
        previewStockpileNetDeltaByCommodityForPlayer(
          game: game,
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(currentOrders: currentOrders),
        ),
        isEmpty,
      );
    });
  });
}
