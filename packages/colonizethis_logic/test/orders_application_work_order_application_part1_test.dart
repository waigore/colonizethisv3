import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders work order application', () {
    const ow = 'oldWorld';
    const provinceId = 'oldWorld|P1';
    const tileKey = 'oldWorld|P1|0|0';

    TileMapResult tileMapWithTerrain(TerrainType terrain) {
      return TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P1'],
        ],
        terrainGrid: [
          [terrain],
        ],
      );
    }

    test(
      'prospect adds tile to playerProspectedTiles when terrain eligible',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetProspect,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(
          game,
          orders,
          tileMapByRegion: {ow: tileMapWithTerrain(TerrainType.hills)},
        );
        expect(next.worldState.playerProspectedTiles['p1'], contains(tileKey));
        final explorerAfter = next.worldState.oldWorld.units.single;
        expect(explorerAfter.tileKey, tileKey);
        expect(explorerAfter.status, UnitStatus.idle);
        expect(explorerAfter.currentWork, isNull);
        expect(explorerAfter.originTileKey, isNull);
        expect(explorerAfter.assignedTileKey, isNull);
      },
    );

    test('prospect on non-mineral-eligible terrain does not add tile', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetProspect,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(
        game,
        orders,
        tileMapByRegion: {ow: tileMapWithTerrain(TerrainType.plains)},
      );
      final prospected =
          next.worldState.playerProspectedTiles['p1'] ?? const <String>{};
      expect(prospected, isNot(contains(tileKey)));
    });

    test(
      'prospect adds tile when mineral resource present without tile map',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKey: 'iron'},
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetProspect,
                targetTileKey: tileKey,
              ),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.playerProspectedTiles['p1'], contains(tileKey));
      },
    );

    test(
      'prospect does not add tile when non-mineral resource present without tile map',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKey: 'grain'},
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetProspect,
                targetTileKey: tileKey,
              ),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final prospected =
            next.worldState.playerProspectedTiles['p1'] ?? const <String>{};
        expect(prospected, isNot(contains(tileKey)));
      },
    );

    test(
      'build_improvement work order sets currentWork then completes when totalTurns=1',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final cost = workOrderCostBuildImprovement(0);
        var stockpile = const Stockpile();
        for (final e in cost.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value);
        }
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKey: 'grain'},
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: stockpile,
            ),
          ],
        );
        final orders = Orders(
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
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        // totalTurns=1 for build_improvement at level 0, so work completes in same phase; unit is idle and tile improved.
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
        expect(next.worldState.tileState.improvementLevel(tileKey), 1);
      },
    );

    test(
      'build_fort assigns currentWork.totalTurns from totalTurnsForWork (fort level)',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeEngineer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final cost = workOrderCostBuildFort(1);
        var stockpile = const Stockpile();
        for (final e in cost.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value);
        }
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: provinceId,
                  regionId: ow,
                  ownerId: 'p1',
                  fortLevel: 1,
                ),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: stockpile,
              techUnlocked: const {kTechIdMineEngineering: true},
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetBuildFort,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        expect(
          u.currentWork!.totalTurns,
          totalTurnsForWork(kWorkTargetBuildFort, fortLevel: 1),
        );
        expect(u.currentWork!.remainingTurns, 1);
        expect(u.originTileKey, tileKey);
        expect(u.assignedTileKey, tileKey);
        expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
      },
    );
  });
}
