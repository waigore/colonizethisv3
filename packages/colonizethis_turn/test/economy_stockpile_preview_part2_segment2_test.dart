import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'economy_stockpile_preview_test_support.dart';

/// Pending material-backed work targets (part 2 segment 2).
/// SPEC/ui/production-panel.md, SPEC/game/stockpiles-and-production.md.
void main() {
  suppressLogsForTests();

  group('previewStockpileNetDeltaByCommodityForPlayer', () {
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
          final game = singlePlayerWorkPreviewGame(
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
            inputs: economyPreviewInputs(currentOrders: orders),
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
          final game = singlePlayerWorkPreviewGame(
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
            inputs: economyPreviewInputs(currentOrders: orders),
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
          final game = singlePlayerWorkPreviewGame(
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
            inputs: economyPreviewInputs(currentOrders: orders),
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
    });
  });
}
