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
                  type: kUnitTypeBuilder,
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
                  type: kUnitTypeBuilder,
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
                type: kUnitTypeBuilder,
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

    group('pending material-backed work targets', () {
      test('deducts each supported target in pending build costs phase', () {
        const tileKey = 'oldWorld|ow|p1|0|0';
        final targets =
            <({String target, String unitType, Map<String, int> cost})>[
              (
                target: kWorkTargetBuildImprovement,
                unitType: kUnitTypeBuilder,
                cost: {
                  CommodityCatalog.lumber.id: 1,
                  CommodityCatalog.castIron.id: 1,
                },
              ),
              (
                target: kWorkTargetUpgradeTown,
                unitType: kUnitTypeBuilder,
                cost: {
                  CommodityCatalog.lumber.id: 1,
                  CommodityCatalog.castIron.id: 1,
                },
              ),
              (
                target: kWorkTargetBuildRoad,
                unitType: kUnitTypeEngineer,
                cost: {
                  CommodityCatalog.lumber.id: 1,
                  CommodityCatalog.castIron.id: 1,
                },
              ),
              (
                target: kWorkTargetBuildPort,
                unitType: kUnitTypeEngineer,
                cost: {
                  CommodityCatalog.lumber.id: 1,
                  CommodityCatalog.castIron.id: 1,
                },
              ),
              (
                target: kWorkTargetBuildFort,
                unitType: kUnitTypeEngineer,
                cost: {
                  CommodityCatalog.lumber.id: 3,
                  CommodityCatalog.bronze.id: 3,
                },
              ),
              (
                target: kWorkTargetBuildRail,
                unitType: kUnitTypeRailBuilder,
                cost: {
                  CommodityCatalog.lumber.id: 2,
                  CommodityCatalog.steel.id: 2,
                },
              ),
            ];

        for (final t in targets) {
          final game = _singlePlayerWorkPreviewGame(
            playerStockpile: const Stockpile()
                .applyDelta(CommodityCatalog.lumber.id, 50)
                .applyDelta(CommodityCatalog.castIron.id, 50)
                .applyDelta(CommodityCatalog.bronze.id, 50)
                .applyDelta(CommodityCatalog.steel.id, 50),
            units: [
              Unit(
                id: 'u1',
                type: t.unitType,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
            ],
            tileState: const TileMapState().setImprovement(tileKey, 0),
          );
          final orders = Orders(
            workOrdersByPlayerId: {
              'p1': [
                WorkOrder(
                  unitId: 'u1',
                  target: t.target,
                  targetTileKey: tileKey,
                ),
              ],
            },
          );
          final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
            game: game,
            topology: const MapTopology(),
            playerId: 'p1',
            currentOrders: orders,
          );
          final pending =
              phases[EconomyPreviewStockpilePhase.pendingBuildCosts]!;
          for (final e in t.cost.entries) {
            expect(
              pending[e.key],
              -e.value,
              reason: 'target=${t.target} commodity=${e.key}',
            );
          }
          expectPhaseDeltasSumToNet(
            game: game,
            playerId: 'p1',
            currentOrders: orders,
          );
        }
      });

      test(
        'mixed target list aggregates and keeps sequential affordability',
        () {
          const tileKey = 'oldWorld|ow|p1|0|0';
          final game = _singlePlayerWorkPreviewGame(
            playerStockpile: const Stockpile()
                .applyDelta(CommodityCatalog.lumber.id, 30)
                .applyDelta(CommodityCatalog.castIron.id, 20)
                .applyDelta(CommodityCatalog.bronze.id, 10)
                .applyDelta(CommodityCatalog.steel.id, 10),
            units: [
              Unit(
                id: 'b1',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
              Unit(
                id: 'b2',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
              Unit(
                id: 'e1',
                type: kUnitTypeEngineer,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
              Unit(
                id: 'e2',
                type: kUnitTypeEngineer,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
              Unit(
                id: 'e3',
                type: kUnitTypeEngineer,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
              Unit(
                id: 'r1',
                type: kUnitTypeRailBuilder,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
            ],
            tileState: const TileMapState().setImprovement(tileKey, 0),
          );
          final orders = const Orders(
            workOrdersByPlayerId: {
              'p1': [
                WorkOrder(
                  unitId: 'b1',
                  target: kWorkTargetBuildImprovement,
                  targetTileKey: tileKey,
                ),
                WorkOrder(
                  unitId: 'b2',
                  target: kWorkTargetUpgradeTown,
                  targetTileKey: tileKey,
                ),
                WorkOrder(
                  unitId: 'e1',
                  target: kWorkTargetBuildRoad,
                  targetTileKey: tileKey,
                ),
                WorkOrder(
                  unitId: 'e2',
                  target: kWorkTargetBuildPort,
                  targetTileKey: tileKey,
                ),
                WorkOrder(
                  unitId: 'e3',
                  target: kWorkTargetBuildFort,
                  targetTileKey: tileKey,
                ),
                WorkOrder(
                  unitId: 'r1',
                  target: kWorkTargetBuildRail,
                  targetTileKey: tileKey,
                ),
              ],
            },
          );
          final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
            game: game,
            topology: const MapTopology(),
            playerId: 'p1',
            currentOrders: orders,
          );
          final pending =
              phases[EconomyPreviewStockpilePhase.pendingBuildCosts]!;
          expect(pending[CommodityCatalog.lumber.id], -9);
          expect(pending[CommodityCatalog.castIron.id], -4);
          expect(pending[CommodityCatalog.bronze.id], -3);
          expect(pending[CommodityCatalog.steel.id], -2);
          expectPhaseDeltasSumToNet(
            game: game,
            playerId: 'p1',
            currentOrders: orders,
          );
        },
      );

      test(
        'later order does not deduct when earlier orders consume affordability',
        () {
          const tileKey = 'oldWorld|ow|p1|0|0';
          final game = _singlePlayerWorkPreviewGame(
            playerStockpile: const Stockpile()
                .applyDelta(CommodityCatalog.lumber.id, 2)
                .applyDelta(CommodityCatalog.castIron.id, 2),
            units: [
              Unit(
                id: 'e1',
                type: kUnitTypeEngineer,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
              Unit(
                id: 'e2',
                type: kUnitTypeEngineer,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
              Unit(
                id: 'b1',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: 'ow|p1',
                tileKey: tileKey,
              ),
            ],
            tileState: const TileMapState().setImprovement(tileKey, 0),
          );
          final orders = const Orders(
            workOrdersByPlayerId: {
              'p1': [
                WorkOrder(
                  unitId: 'e1',
                  target: kWorkTargetBuildRoad,
                  targetTileKey: tileKey,
                ),
                WorkOrder(
                  unitId: 'e2',
                  target: kWorkTargetBuildPort,
                  targetTileKey: tileKey,
                ),
                WorkOrder(
                  unitId: 'b1',
                  target: kWorkTargetUpgradeTown,
                  targetTileKey: tileKey,
                ),
              ],
            },
          );
          final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
            game: game,
            topology: const MapTopology(),
            playerId: 'p1',
            currentOrders: orders,
          );
          final pending =
              phases[EconomyPreviewStockpilePhase.pendingBuildCosts]!;
          expect(pending[CommodityCatalog.lumber.id], -2);
          expect(pending[CommodityCatalog.castIron.id], -2);
          expectPhaseDeltasSumToNet(
            game: game,
            playerId: 'p1',
            currentOrders: orders,
          );
        },
      );

      test(
        'skips target when unit missing busy disallowed invalid tile or unaffordable',
        () {
          const tileKey = 'oldWorld|ow|p1|0|0';
          final targets =
              <({String target, String unitType, Map<String, int> cost})>[
                (
                  target: kWorkTargetBuildImprovement,
                  unitType: kUnitTypeBuilder,
                  cost: {
                    CommodityCatalog.lumber.id: 1,
                    CommodityCatalog.castIron.id: 1,
                  },
                ),
                (
                  target: kWorkTargetUpgradeTown,
                  unitType: kUnitTypeBuilder,
                  cost: {
                    CommodityCatalog.lumber.id: 1,
                    CommodityCatalog.castIron.id: 1,
                  },
                ),
                (
                  target: kWorkTargetBuildRoad,
                  unitType: kUnitTypeEngineer,
                  cost: {
                    CommodityCatalog.lumber.id: 1,
                    CommodityCatalog.castIron.id: 1,
                  },
                ),
                (
                  target: kWorkTargetBuildPort,
                  unitType: kUnitTypeEngineer,
                  cost: {
                    CommodityCatalog.lumber.id: 1,
                    CommodityCatalog.castIron.id: 1,
                  },
                ),
                (
                  target: kWorkTargetBuildFort,
                  unitType: kUnitTypeEngineer,
                  cost: {
                    CommodityCatalog.lumber.id: 3,
                    CommodityCatalog.bronze.id: 3,
                  },
                ),
                (
                  target: kWorkTargetBuildRail,
                  unitType: kUnitTypeRailBuilder,
                  cost: {
                    CommodityCatalog.lumber.id: 2,
                    CommodityCatalog.steel.id: 2,
                  },
                ),
              ];

          for (final t in targets) {
            final validBaseStockpile = const Stockpile()
                .applyDelta(CommodityCatalog.lumber.id, 20)
                .applyDelta(CommodityCatalog.castIron.id, 20)
                .applyDelta(CommodityCatalog.bronze.id, 20)
                .applyDelta(CommodityCatalog.steel.id, 20);

            final missingUnitGame = _singlePlayerWorkPreviewGame(
              playerStockpile: validBaseStockpile,
              units: [],
              tileState: const TileMapState().setImprovement(tileKey, 0),
            );
            final missingUnitOrders = Orders(
              workOrdersByPlayerId: {
                'p1': [
                  WorkOrder(
                    unitId: 'missing',
                    target: t.target,
                    targetTileKey: tileKey,
                  ),
                ],
              },
            );
            expect(
              previewStockpilePhaseDeltasByCommodityForPlayer(
                game: missingUnitGame,
                topology: const MapTopology(),
                playerId: 'p1',
                currentOrders: missingUnitOrders,
              )[EconomyPreviewStockpilePhase.pendingBuildCosts],
              isEmpty,
              reason: 'missing unit target=${t.target}',
            );

            final busyUnitGame = _singlePlayerWorkPreviewGame(
              playerStockpile: validBaseStockpile,
              units: [
                Unit(
                  id: 'u1',
                  type: t.unitType,
                  ownerId: 'p1',
                  locationProvinceId: 'ow|p1',
                  tileKey: tileKey,
                  status: UnitStatus.working,
                  currentWork: const CurrentWork(
                    workTarget: kWorkTargetBuildImprovement,
                    tileKey: tileKey,
                    totalTurns: 1,
                    remainingTurns: 1,
                  ),
                ),
              ],
              tileState: const TileMapState().setImprovement(tileKey, 0),
            );
            final busyOrders = Orders(
              workOrdersByPlayerId: {
                'p1': [
                  WorkOrder(
                    unitId: 'u1',
                    target: t.target,
                    targetTileKey: tileKey,
                  ),
                ],
              },
            );
            expect(
              previewStockpilePhaseDeltasByCommodityForPlayer(
                game: busyUnitGame,
                topology: const MapTopology(),
                playerId: 'p1',
                currentOrders: busyOrders,
              )[EconomyPreviewStockpilePhase.pendingBuildCosts],
              isEmpty,
              reason: 'busy unit target=${t.target}',
            );

            final disallowedUnitGame = _singlePlayerWorkPreviewGame(
              playerStockpile: validBaseStockpile,
              units: [
                Unit(
                  id: 'u1',
                  type: 'peasant_levies',
                  ownerId: 'p1',
                  locationProvinceId: 'ow|p1',
                  tileKey: tileKey,
                ),
              ],
              tileState: const TileMapState().setImprovement(tileKey, 0),
            );
            final disallowedOrders = Orders(
              workOrdersByPlayerId: {
                'p1': [
                  WorkOrder(
                    unitId: 'u1',
                    target: t.target,
                    targetTileKey: tileKey,
                  ),
                ],
              },
            );
            expect(
              previewStockpilePhaseDeltasByCommodityForPlayer(
                game: disallowedUnitGame,
                topology: const MapTopology(),
                playerId: 'p1',
                currentOrders: disallowedOrders,
              )[EconomyPreviewStockpilePhase.pendingBuildCosts],
              isEmpty,
              reason: 'disallowed unit target=${t.target}',
            );

            final invalidTileGame = _singlePlayerWorkPreviewGame(
              playerStockpile: validBaseStockpile,
              units: [
                Unit(
                  id: 'u1',
                  type: t.unitType,
                  ownerId: 'p1',
                  locationProvinceId: 'ow|p1',
                  tileKey: tileKey,
                ),
              ],
              tileState: const TileMapState().setImprovement(tileKey, 0),
            );
            final invalidTileOrders = Orders(
              workOrdersByPlayerId: {
                'p1': [
                  WorkOrder(unitId: 'u1', target: t.target, targetTileKey: ''),
                ],
              },
            );
            expect(
              previewStockpilePhaseDeltasByCommodityForPlayer(
                game: invalidTileGame,
                topology: const MapTopology(),
                playerId: 'p1',
                currentOrders: invalidTileOrders,
              )[EconomyPreviewStockpilePhase.pendingBuildCosts],
              isEmpty,
              reason: 'invalid target key target=${t.target}',
            );

            final insufficientStockpile = t.cost.entries.fold<Stockpile>(
              const Stockpile(),
              (acc, e) {
                final amount = e.key == t.cost.keys.first
                    ? e.value - 1
                    : e.value;
                return acc.applyDelta(e.key, amount);
              },
            );
            final insufficientGame = _singlePlayerWorkPreviewGame(
              playerStockpile: insufficientStockpile,
              units: [
                Unit(
                  id: 'u1',
                  type: t.unitType,
                  ownerId: 'p1',
                  locationProvinceId: 'ow|p1',
                  tileKey: tileKey,
                ),
              ],
              tileState: const TileMapState().setImprovement(tileKey, 0),
            );
            final insufficientOrders = Orders(
              workOrdersByPlayerId: {
                'p1': [
                  WorkOrder(
                    unitId: 'u1',
                    target: t.target,
                    targetTileKey: tileKey,
                  ),
                ],
              },
            );
            expect(
              previewStockpilePhaseDeltasByCommodityForPlayer(
                game: insufficientGame,
                topology: const MapTopology(),
                playerId: 'p1',
                currentOrders: insufficientOrders,
              )[EconomyPreviewStockpilePhase.pendingBuildCosts],
              isEmpty,
              reason: 'insufficient stockpile target=${t.target}',
            );
            expectPhaseDeltasSumToNet(
              game: insufficientGame,
              playerId: 'p1',
              currentOrders: insufficientOrders,
            );
          }
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

Game _singlePlayerWorkPreviewGame({
  required Stockpile playerStockpile,
  required List<Unit> units,
  TileMapState tileState = const TileMapState(),
}) {
  final player = Player(
    id: 'p1',
    displayName: 'A',
    isHuman: true,
    stockpile: playerStockpile,
  );
  return Game(
    id: 't',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        units: units,
        provinces: const [
          Province(
            id: 'ow|p1',
            regionId: 'oldWorld',
            ownerId: 'p1',
            fortLevel: 0,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: [player],
  );
}
