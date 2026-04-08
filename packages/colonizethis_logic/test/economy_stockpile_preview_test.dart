import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Stockpile preview for production panel. SPEC/ui/production-panel.md,
/// SPEC/game/stockpiles-and-production.md.
void main() {
  suppressLogsForTests();

  void expectPhaseDeltasSumToNet({
    required Game game,
    required String playerId,
    Orders pendingOrders = const Orders(),
    Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
    List<AssignedRecipe> defaultAssignments = const [],
    Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  }) {
    final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
      game: game,
      topology: const MapTopology(),
      playerId: playerId,
      pendingOrders: pendingOrders,
      extractedByPlayerId: extractedByPlayerId,
      defaultAssignments: defaultAssignments,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    );
    final net = previewStockpileNetDeltaByCommodityForPlayer(
      game: game,
      topology: const MapTopology(),
      playerId: playerId,
      pendingOrders: pendingOrders,
      extractedByPlayerId: extractedByPlayerId,
      defaultAssignments: defaultAssignments,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    );
    final keys = <String>{};
    for (final m in phases.values) {
      keys.addAll(m.keys);
    }
    keys.addAll(net.keys);
    for (final c in keys) {
      var sum = 0;
      for (final p in EconomyPreviewStockpilePhase.values) {
        sum += phases[p]?[c] ?? 0;
      }
      expect(sum, net[c] ?? 0, reason: 'commodity $c phase sum vs net');
    }
  }

  group('previewStockpilePhaseDeltasByCommodityForPlayer', () {
    test('unknown player yields empty maps per phase', () {
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile(),
      );
      final game = _singlePlayerGame(player);
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
      final game = _singlePlayerGame(player);
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        extractedByPlayerId: {
          'p1': {CommodityCatalog.grain.id: 4},
        },
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
        final game = _singlePlayerGame(player);
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
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
          newWorld: const RegionData(),
        ),
        players: [player],
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
      final game = _singlePlayerGame(player);
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        defaultAssignmentsByPlayerId: {
          'p1': const [
            AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 10),
          ],
        },
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

    test('combined: extraction + riches + consumption + production', () {
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.grain.id, 100)
          .applyDelta(CommodityCatalog.meat.id, 100)
          .applyDelta(CommodityCatalog.timber.id, 20)
          .applyDelta(CommodityCatalog.gems.id, 1);
      const workers = WorkerPool(peasants: 2);
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: stockpile,
        workerPool: workers,
      );
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        extractedByPlayerId: {
          'p1': {CommodityCatalog.grain.id: 5},
        },
        defaultAssignmentsByPlayerId: {
          'p1': const [
            AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 4),
          ],
        },
      );
      expect(delta[CommodityCatalog.gems.id], -1);
      expect(delta[CommodityCatalog.timber.id], -2);
      expect(delta[CommodityCatalog.lumber.id], 1);
      expect(delta[CommodityCatalog.grain.id], 2);
      expectPhaseDeltasSumToNet(
        game: game,
        playerId: 'p1',
        extractedByPlayerId: {
          'p1': {CommodityCatalog.grain.id: 5},
        },
        defaultAssignmentsByPlayerId: {
          'p1': const [
            AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 4),
          ],
        },
      );
    });

    test('pending build/train costs are included before economy phases', () {
      final stockpile = const Stockpile().applyDelta(
        CommodityCatalog.paper.id,
        2,
      );
      final player = Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 10),
        treasury: 1000,
      );
      final game = _singlePlayerGame(player);
      final pendingOrders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': const [
            BuildUnitOrder(
              unitType: 'Builder',
              isMilitary: false,
              spawnProvinceId: 'oldWorld|p1',
            ),
          ],
        },
      );
      final delta = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        pendingOrders: pendingOrders,
      );
      expect(delta[CommodityCatalog.paper.id], -2);
      final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        pendingOrders: pendingOrders,
      );
      expect(
        phases[EconomyPreviewStockpilePhase
            .pendingBuildTrainCosts]![CommodityCatalog.paper.id],
        -2,
      );
      expectPhaseDeltasSumToNet(
        game: game,
        playerId: 'p1',
        pendingOrders: pendingOrders,
      );
    });
  });
}

Game _singlePlayerGame(Player player) {
  return Game(
    id: 't',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
}
