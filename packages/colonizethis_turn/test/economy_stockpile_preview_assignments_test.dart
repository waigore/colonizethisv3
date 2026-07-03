import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'economy_stockpile_preview_test_support.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Skips / combined net preview scenarios (part 2 segment 3).
/// SPEC/ui/production-panel.md, SPEC/game/stockpiles-and-production.md.
void main() {
  suppressLogsForTests();

  group('previewStockpileNetDeltaByCommodityForPlayer', () {
    group('pending material-backed work targets', () {
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

            final missingUnitGame = TestFixtures.singlePlayerWorkPreviewGame(
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
                inputs: economyPreviewInputs(currentOrders: missingUnitOrders),
              )[EconomyPreviewStockpilePhase.pendingBuildCosts],
              isEmpty,
              reason: 'missing unit target=${t.target}',
            );

            final busyUnitGame = TestFixtures.singlePlayerWorkPreviewGame(
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
                inputs: economyPreviewInputs(currentOrders: busyOrders),
              )[EconomyPreviewStockpilePhase.pendingBuildCosts],
              isEmpty,
              reason: 'busy unit target=${t.target}',
            );

            final disallowedUnitGame = TestFixtures.singlePlayerWorkPreviewGame(
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
                inputs: economyPreviewInputs(currentOrders: disallowedOrders),
              )[EconomyPreviewStockpilePhase.pendingBuildCosts],
              isEmpty,
              reason: 'disallowed unit target=${t.target}',
            );

            final invalidTileGame = TestFixtures.singlePlayerWorkPreviewGame(
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
                inputs: economyPreviewInputs(currentOrders: invalidTileOrders),
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
            final insufficientGame = TestFixtures.singlePlayerWorkPreviewGame(
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
                inputs: economyPreviewInputs(
                  currentOrders: insufficientOrders,
                ),
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
        inputs: economyPreviewInputs(
          extractedByPlayerId: {
            'p1': {CommodityCatalog.grain.id: 5},
          },
          defaultAssignmentsByPlayerId: {
            'p1': const [
              AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 4),
            ],
          },
        ),
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
