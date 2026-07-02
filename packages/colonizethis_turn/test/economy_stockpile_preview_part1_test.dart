import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'economy_stockpile_preview_test_support.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

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
      final game = TestFixtures.singlePlayerGame(player);
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
    test('extraction only: delta matches injected extraction totals', () {
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile(),
      );
      final game = TestFixtures.singlePlayerGame(player);
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(
          extractedByPlayerId: {
            'p1': {CommodityCatalog.grain.id: 4},
          },
        ),
      );
      expect(delta[CommodityCatalog.grain.id], 4);
      expect(delta.length, 1);
      expectPhaseDeltasSumToNet(
        game: game,
        playerId: 'p1',
        extractedByPlayerId: {
          'p1': {CommodityCatalog.grain.id: 4},
        },
      );
    });

    test(
      'riches only: riches commodities removed, no production assignments',
      () {
        final player = Player(
          id: 'p1',
          displayName: 'A',
          isHuman: true,
          stockpile: const Stockpile().applyDelta(CommodityCatalog.gold.id, 2),
        );
        final game = TestFixtures.singlePlayerGame(player);
        final delta = previewStockpileNetDeltaByCommodityForPlayer(
          game: game,
          topology: const MapTopology(),
          playerId: 'p1',
        );
        expect(delta[CommodityCatalog.gold.id], -2);
        final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
          game: game,
          topology: const MapTopology(),
          playerId: 'p1',
        );
        expect(
          phases[EconomyPreviewStockpilePhase
              .richesToTreasury]![CommodityCatalog.gold.id],
          -2,
        );
        expectPhaseDeltasSumToNet(game: game, playerId: 'p1');
      },
    );

    test('consumption only: military food reduces grain', () {
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 10),
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
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
      );
      expect(delta[CommodityCatalog.grain.id], -1);
      expectPhaseDeltasSumToNet(game: game, playerId: 'p1');
    });

    test('production only: net reflects recipe IO after consumption', () {
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 50)
          .applyDelta(CommodityCatalog.meat.id, 50)
          .applyDelta(CommodityCatalog.timber.id, 20);
      const workers = WorkerPool(peasants: 10);
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: stockpile,
        workerPool: workers,
      );
      final game = TestFixtures.singlePlayerGame(player);
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(
          defaultAssignmentsByPlayerId: {
            'p1': const [
              AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 10),
            ],
          },
        ),
      );
      expect(delta[CommodityCatalog.timber.id], -10);
      expect(delta[CommodityCatalog.lumber.id], 5);
      expect(delta[CommodityCatalog.grain.id] != 0, isTrue);
      expectPhaseDeltasSumToNet(
        game: game,
        playerId: 'p1',
        defaultAssignmentsByPlayerId: {
          'p1': const [
            AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 10),
          ],
        },
      );
    });

    test('pending build orders are included before economy phases', () {
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.paper.id, 6)
            .applyDelta(CommodityCatalog.grain.id, 50)
            .applyDelta(CommodityCatalog.meat.id, 50),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 5000,
      );
      final game = TestFixtures.singlePlayerGame(player);
      const currentOrders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary: false,
              spawnProvinceId: 'ow|p1',
            ),
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary: false,
              spawnProvinceId: 'ow|p1',
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
      expect(delta[CommodityCatalog.paper.id], -4);
      expect(
        phases[EconomyPreviewStockpilePhase.pendingBuildCosts]![CommodityCatalog
            .paper
            .id],
        -4,
      );
      expectPhaseDeltasSumToNet(
        game: game,
        playerId: 'p1',
        currentOrders: currentOrders,
      );
    });

  });
}
