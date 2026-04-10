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
    Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
    Orders currentOrders = const Orders(),
    List<AssignedRecipe> defaultAssignments = const [],
    Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  }) {
    final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
      game: game,
      topology: const MapTopology(),
      playerId: playerId,
      extractedByPlayerId: extractedByPlayerId,
      currentOrders: currentOrders,
      defaultAssignments: defaultAssignments,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    );
    final net = previewStockpileNetDeltaByCommodityForPlayer(
      game: game,
      topology: const MapTopology(),
      playerId: playerId,
      extractedByPlayerId: extractedByPlayerId,
      currentOrders: currentOrders,
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
      final game = _singlePlayerGame(player);
      const currentOrders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Builder',
              isMilitary: false,
              spawnProvinceId: 'ow|p1',
            ),
            BuildUnitOrder(
              unitType: 'Builder',
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
        currentOrders: currentOrders,
      );
      final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
        game: game,
        topology: const MapTopology(),
        playerId: 'p1',
        currentOrders: currentOrders,
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

    test(
      'pending build_improvement work orders deduct in pending build phase',
      () {
        const tileKey = 'oldWorld|ow|p1|0|0';
        final tileState = const TileMapState().setImprovement(tileKey, 0);
        final player = Player(
          id: 'p1',
          displayName: 'A',
          isHuman: true,
          stockpile: const Stockpile()
              .applyDelta(CommodityCatalog.lumber.id, 10)
              .applyDelta(CommodityCatalog.castIron.id, 10),
        );
        final game = Game(
          id: 't',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              units: [
                Unit(
                  id: 'b1',
                  type: 'Builder',
                  ownerId: 'p1',
                  locationProvinceId: 'ow|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: [player],
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
          currentOrders: currentOrders,
        );
        final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
          game: game,
          topology: const MapTopology(),
          playerId: 'p1',
          currentOrders: currentOrders,
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
        final player = Player(
          id: 'p1',
          displayName: 'A',
          isHuman: true,
          stockpile: const Stockpile()
              .applyDelta(CommodityCatalog.lumber.id, 10)
              .applyDelta(CommodityCatalog.castIron.id, 10),
        );
        final game = Game(
          id: 't',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              units: [
                Unit(
                  id: 'b1',
                  type: 'Builder',
                  ownerId: 'p1',
                  locationProvinceId: 'ow|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: [player],
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
          currentOrders: currentOrders,
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
        type: 'Builder',
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
      final gameBusy = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(units: [busyUnit]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [poorPlayer],
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
          currentOrders: ordersBusy,
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
      final gamePoorCost = Game(
        id: 't2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            units: [
              Unit(
                id: 'b2',
                type: 'Builder',
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: const TileMapState().setImprovement(tileKey, 1),
        ),
        players: [playerLowStock],
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
          currentOrders: ordersPoorCost,
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
          currentOrders: currentOrders,
        ),
        isEmpty,
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
