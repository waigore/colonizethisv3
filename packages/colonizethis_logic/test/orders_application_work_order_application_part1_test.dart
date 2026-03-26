import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders work order application', () {
    const ow = 'oldWorld';
    const provinceId = 'oldWorld|P1';
    const tileKey = 'oldWorld|P1|0|0';

    TileMapResult _tileMapWithTerrain(TerrainType terrain) {
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
          type: 'Explorer',
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
                target: 'prospect',
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(
          game,
          orders,
          tileMapByRegion: {ow: _tileMapWithTerrain(TerrainType.hills)},
        );
        expect(next.worldState.playerProspectedTiles['p1'], contains(tileKey));
      },
    );

    test('prospect on non-mineral-eligible terrain does not add tile', () {
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
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
            WorkOrder(unitId: 'u1', target: 'prospect', targetTileKey: tileKey),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(
        game,
        orders,
        tileMapByRegion: {ow: _tileMapWithTerrain(TerrainType.plains)},
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
          type: 'Explorer',
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
                target: 'prospect',
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
          type: 'Explorer',
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
                target: 'prospect',
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
          type: 'Builder',
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
                target: 'build_improvement',
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

    test('steal_tech work order sets currentWork for Spy unit', () {
      const targetProvinceId = 'oldWorld|P2';
      const targetTileKey = 'oldWorld|P2|0|0';
      final spy = Unit(
        id: 'spy1',
        type: 'Spy',
        ownerId: 'p1',
        locationProvinceId: targetProvinceId,
        tileKey: targetTileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: provinceId,
                regionId: ow,
                ownerId: 'p1',
              ), // owner
              const Province(id: targetProvinceId, regionId: ow, ownerId: 'p2'),
            ],
            units: [spy],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              provinceId: [tileKey],
              targetProvinceId: [targetTileKey],
            },
          },
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: provinceId,
          ),
          Player(
            id: 'p2',
            displayName: 'P2',
            isHuman: true,
            capitalProvinceId: targetProvinceId,
            techUnlocked: {'some_tech': true},
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            const WorkOrder(
              unitId: 'spy1',
              target: 'steal_tech',
              targetTileKey: targetTileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final spyAfter = next.worldState.oldWorld.units.single;
      expect(spyAfter.currentWork, isNotNull);
      expect(spyAfter.currentWork!.workTarget, 'steal_tech');
      expect(spyAfter.currentWork!.totalTurns, 5);
      // One turn processed in same phase after applying, so remainingTurns 5 -> 4.
      expect(spyAfter.currentWork!.remainingTurns, 4);
    });

    test('explore work order sets currentWork when province has tiles', () {
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
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
          tileKeysByRegionAndProvince: {
            ow: {
              provinceId: [tileKey, 'oldWorld|P1|1|0'],
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(unitId: 'u1', target: 'explore', targetTileKey: tileKey),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final u = next.worldState.oldWorld.units.single;
      expect(u.currentWork, isNotNull);
      expect(u.currentWork!.workTarget, 'explore');
      expect(u.currentWork!.totalTurns, greaterThanOrEqualTo(1));
      // One turn processed in same phase after applying.
      expect(u.currentWork!.remainingTurns, u.currentWork!.totalTurns - 1);
    });

    test(
      'explore work order totalTurns uses region-scoped formula ceil(3 * tilesInP / maxTilesInRegion)',
      () {
        // Region has two provinces with different tile counts; explorer in the
        // smaller one should get totalTurns = ceil(3 * tilesInP / maxTilesInRegion).
        const ow = 'oldWorld';
        const provinceSmall = '$ow|P1';
        const provinceLarge = '$ow|P2';
        const tileSmall1 = '$ow|P1|0|0';
        const tileSmall2 = '$ow|P1|1|0';
        const tileLarge1 = '$ow|P2|0|0';
        const tileLarge2 = '$ow|P2|1|0';
        const tileLarge3 = '$ow|P2|2|0';
        const tileLarge4 = '$ow|P2|3|0';

        final unit = Unit(
          id: 'u1',
          type: 'Explorer',
          ownerId: 'p1',
          locationProvinceId: provinceSmall,
          tileKey: tileSmall1,
        );

        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceSmall, regionId: ow, ownerId: 'p1'),
                Province(id: provinceLarge, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              ow: {
                provinceSmall: [tileSmall1, tileSmall2], // tilesInP = 2
                provinceLarge: [
                  tileLarge1,
                  tileLarge2,
                  tileLarge3,
                  tileLarge4,
                ], // maxTilesInRegion = 4
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );

        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'u1',
                target: 'explore',
                targetTileKey: tileSmall1,
              ),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;

        // tilesInP = 2, maxTilesInRegion = 4 → ceil(3 * 2 / 4) = ceil(1.5) = 2.
        expect(u.currentWork, isNotNull);
        expect(u.currentWork!.workTarget, 'explore');
        expect(u.currentWork!.totalTurns, 2);
        // One turn processed in same phase after applying.
        expect(u.currentWork!.remainingTurns, 1);
      },
    );

    test('Engineer build_road work order sets currentWork', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final cost = workOrderCostBuildRoad;
      var stockpile = const Stockpile();
      for (final e in cost.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value);
      }
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
              target: 'build_road',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final u = next.worldState.oldWorld.units.single;
      // build_road totalTurns=1, so work completes in same phase; unit idle and road level 1.
      expect(u.currentWork, isNull);
      expect(u.status, UnitStatus.idle);
      expect(next.worldState.tileState.roadLevel(tileKey), 1);
    });

    test(
      'build_port work order sets currentWork when materials sufficient',
      () {
        final unit = Unit(
          id: 'u1',
          type: 'Engineer',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final cost = workOrderMaterialCost('build_port');
        expect(cost, isNotNull);
        var stockpile = const Stockpile();
        for (final e in cost!.entries) {
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
                target: 'build_port',
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        // build_port totalTurns=1, so work completes in same phase; unit idle.
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
      },
    );
  });
}
