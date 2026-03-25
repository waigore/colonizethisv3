import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders (military training costs)', () {
    Game _baseGame({required int peasants, required int treasury}) {
      const playerId = 'p1';
      final player = Player(
        id: playerId,
        displayName: 'Player 1',
        isHuman: true,
        stockpile: const Stockpile(),
        workerPool: WorkerPool(peasants: peasants),
        treasury: treasury,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'P1', regionId: 'oldWorld', ownerId: playerId),
          ],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      return Game(id: 'g', worldState: world, players: [player]);
    }

    Orders _ordersFor(String unitType, {String? spawnProvinceId}) {
      final spawn = spawnProvinceId ?? 'oldWorld|P1';
      return Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: unitType,
              isMilitary:
                  buildUnitCategoryForUnitType(unitType) ==
                  BuildUnitCategory.military,
              spawnProvinceId: spawn,
            ),
          ],
        },
      );
    }

    test('rejects build when treasury is insufficient', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      final game = _baseGame(peasants: 5, treasury: econ.buildTreasuryCost - 1);
      final orders = _ordersFor('peasant_levies');

      final next = applyBuildAndWorkOrders(game, orders);

      // No unit spawned and treasury unchanged.
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(
        next.players.single.workerPool.peasants,
        game.players.single.workerPool.peasants,
      );
    });

    test('rejects build when materials are insufficient', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      // Enough treasury, but empty stockpile (no fabric).
      final game = _baseGame(
        peasants: 5,
        treasury: econ.buildTreasuryCost + 10,
      );
      final orders = _ordersFor('peasant_levies');

      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(
        next.players.single.workerPool.peasants,
        game.players.single.workerPool.peasants,
      );
    });

    test('applies treasury, stockpile and worker costs when valid', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final entry in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(
          entry.key,
          entry.value + 1,
        ); // small surplus
      }

      final player = Player(
        id: 'p1',
        displayName: 'Player 1',
        isHuman: true,
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 3),
        treasury: econ.buildTreasuryCost + 5,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(
          provinces: [Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1')],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g', worldState: world, players: [player]);
      final orders = _ordersFor('peasant_levies');

      final next = applyBuildAndWorkOrders(game, orders);
      final nextPlayer = next.players.single;

      // Exactly one new unit of requested type was created.
      expect(next.worldState.oldWorld.units.length, 1);
      expect(next.worldState.oldWorld.units.single.type, 'peasant_levies');

      // Treasury reduced by training cost.
      expect(nextPlayer.treasury, player.treasury - econ.buildTreasuryCost);

      // One peasant consumed.
      expect(nextPlayer.workerPool.peasants, player.workerPool.peasants - 1);

      // Materials reduced by required inputs.
      for (final entry in econ.buildInputs.entries) {
        final before = player.stockpile.quantityOf(entry.key);
        final after = nextPlayer.stockpile.quantityOf(entry.key);
        expect(after, before - entry.value);
      }
    });

    test('returns game unchanged when no build or work orders', () {
      final game = _baseGame(peasants: 2, treasury: 100);
      final next = applyBuildAndWorkOrders(game, const Orders());
      expect(
        next.worldState.oldWorld.units.length,
        game.worldState.oldWorld.units.length,
      );
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(
        next.players.single.workerPool.peasants,
        game.players.single.workerPool.peasants,
      );
    });

    test(
      'ship build adds ship to fleet when topology and capital with sea',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
        );
        final player = Player(
          id: 'p1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|P1',
          stockpile: const Stockpile(),
          workerPool: const WorkerPool(peasants: 0),
          treasury: 100,
          techUnlocked: {'superior_hull_design': true},
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        );
        final game = Game(id: 'g', worldState: world, players: [player]);
        final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
        var stockpile = const Stockpile();
        for (final e in shipEcon.buildInputs.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value + 1);
        }
        final gameWithStock = game.copyWith(
          players: [
            player.copyWith(
              stockpile: stockpile,
              treasury: shipEcon.buildTreasuryCost + 10,
            ),
          ],
        );
        final orders = Orders(
          buildUnitOrdersByPlayerId: {
            'p1': [
              BuildUnitOrder(
                unitType: 'fluyte',
                isMilitary:
                    buildUnitCategoryForUnitType('fluyte') ==
                    BuildUnitCategory.military,
                spawnProvinceId: 'oldWorld|P1',
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(
          gameWithStock,
          orders,
          topology: topology,
        );
        expect(next.worldState.fleets, isNotEmpty);
        expect(
          next.worldState.fleets.any(
            (f) => f.ownerId == 'p1' && f.shipTypeIds.contains('fluyte'),
          ),
          isTrue,
        );
      },
    );

    test('second naval build adds ship to existing home fleet', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(
            id: 'Sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'Sea1')],
      );
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value * 2 + 1);
      }
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: '$ow|P1',
        stockpile: stockpile,
        treasury: shipEcon.buildTreasuryCost * 2 + 10,
        techUnlocked: {'superior_hull_design': true},
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
          units: [],
        ),
        newWorld: const RegionData(),
        fleets: [
          Fleet(
            id: 'fleet_p1',
            ownerId: 'p1',
            seaZoneId: 'Sea1',
            regionId: ow,
            shipTypeIds: ['fluyte'],
          ),
        ],
      );
      final game = Game(id: 'g', worldState: world, players: [player]);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'fluyte',
              isMilitary:
                  buildUnitCategoryForUnitType('fluyte') ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$ow|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      final p1Fleet = next.worldState.fleets
          .where((f) => f.ownerId == 'p1')
          .single;
      expect(p1Fleet.shipTypeIds.length, 2);
      expect(p1Fleet.shipTypeIds, contains('fluyte'));
    });
  });

  group('applyBuildAndWorkOrders (civilian training costs)', () {
    Game _civilianGame({
      required int treasury,
      required int paper,
      Map<String, bool>? techUnlocked,
    }) {
      const playerId = 'p1';
      var stockpile = const Stockpile();
      if (paper > 0) {
        stockpile = stockpile.applyDelta(CommodityCatalog.paper.id, paper);
      }
      final player = Player(
        id: playerId,
        displayName: 'Player 1',
        isHuman: true,
        capitalProvinceId: 'oldWorld|P1',
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 0),
        treasury: treasury,
        techUnlocked: techUnlocked,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'P1', regionId: 'oldWorld', ownerId: playerId),
          ],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      return Game(id: 'g', worldState: world, players: [player]);
    }

    test('rejects civilian build when treasury insufficient', () {
      final game = _civilianGame(treasury: 999, paper: 2);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Builder',
              isMilitary:
                  buildUnitCategoryForUnitType('Builder') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(
        next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
        game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
      );
    });

    test('rejects civilian build when paper insufficient', () {
      final game = _civilianGame(treasury: 1000, paper: 0);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Builder',
              isMilitary:
                  buildUnitCategoryForUnitType('Builder') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.treasury, game.players.single.treasury);
    });

    test('applies treasury and paper cost when civilian build valid', () {
      const cash = 1000;
      const paperQty = 2;
      final game = _civilianGame(treasury: cash + 100, paper: paperQty + 1);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Builder',
              isMilitary:
                  buildUnitCategoryForUnitType('Builder') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units.length, 1);
      expect(next.worldState.oldWorld.units.single.type, 'Builder');
      expect(next.players.single.treasury, game.players.single.treasury - cash);
      expect(
        next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
        game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id) -
            paperQty,
      );
    });

    test('Merchant requires merchant_companies tech', () {
      const cash = 2000;
      const paperQty = 4;
      final gameNoTech = _civilianGame(
        treasury: cash + 100,
        paper: paperQty + 1,
        techUnlocked: {},
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Merchant',
              isMilitary:
                  buildUnitCategoryForUnitType('Merchant') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final nextNoTech = applyBuildAndWorkOrders(gameNoTech, orders);
      expect(nextNoTech.worldState.oldWorld.units, isEmpty);
      expect(
        nextNoTech.players.single.treasury,
        gameNoTech.players.single.treasury,
      );

      final gameWithTech = _civilianGame(
        treasury: cash + 100,
        paper: paperQty + 1,
        techUnlocked: {'merchant_companies': true},
      );
      final nextWithTech = applyBuildAndWorkOrders(gameWithTech, orders);
      expect(nextWithTech.worldState.oldWorld.units.length, 1);
      expect(nextWithTech.worldState.oldWorld.units.single.type, 'Merchant');
      expect(
        nextWithTech.players.single.treasury,
        gameWithTech.players.single.treasury - cash,
      );
      expect(
        nextWithTech.players.single.stockpile.quantityOf(
          CommodityCatalog.paper.id,
        ),
        gameWithTech.players.single.stockpile.quantityOf(
              CommodityCatalog.paper.id,
            ) -
            paperQty,
      );
    });
  });

  group('applyBuildAndWorkOrders work completion', () {
    const ow = 'oldWorld';
    const tileKey = 'oldWorld|P1|0|0';
    const provinceId = 'oldWorld|P1';

    // Non-empty orders so applyBuildAndWorkOrders does not return early (empty build list still counts).
    Orders _ordersToTriggerProcessWork() =>
        Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]});

    TileMapResult _simpleTileMap() {
      return TileMapResult(
        width: 3,
        height: 3,
        grid: const [
          ['P1', 'P1', 'P1'],
          ['P1', 'P1', 'P1'],
          ['P1', 'P1', 'P1'],
        ],
      );
    }

    test(
      'build_improvement completion increases improvement level and clears currentWork',
      () {
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: 'build_improvement',
            tileKey: tileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
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
            tileState: tileState,
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final next = applyBuildAndWorkOrders(
          game,
          _ordersToTriggerProcessWork(),
        );
        expect(next.worldState.tileState.improvementLevel(tileKey), 1);
      },
    );

    test(
      'work cancelled when province containing target tile is conquered (#376)',
      () {
        // Unit p1 is working on a tile in P1; province P1 is conquered by p2.
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: 'build_improvement',
            tileKey: tileKey,
            totalTurns: 2,
            remainingTurns: 2,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              // Province owned by p2 (conquered); unit still belongs to p1.
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p2'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: true),
          ],
        );
        final next = applyBuildAndWorkOrders(
          game,
          _ordersToTriggerProcessWork(),
        );
        final uAfter = next.worldState.oldWorld.units.single;
        expect(uAfter.status, UnitStatus.idle);
        expect(uAfter.currentWork, isNull);
        // Improvement not applied (work was cancelled).
        expect(next.worldState.tileState.improvementLevel(tileKey), 0);
      },
    );

    test(
      'multi-turn work decrements remainingTurns and completes only when zero',
      () {
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: CurrentWork(
            workTarget: 'build_improvement',
            tileKey: tileKey,
            totalTurns: 2,
            remainingTurns: 2,
          ),
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
            tileState: tileState,
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final afterFirst = applyBuildAndWorkOrders(
          game,
          _ordersToTriggerProcessWork(),
        );
        expect(afterFirst.worldState.tileState.improvementLevel(tileKey), 0);
        final uAfterFirst = afterFirst.worldState.oldWorld.units.single;
        expect(uAfterFirst.currentWork!.remainingTurns, 1);
        final afterSecond = applyBuildAndWorkOrders(
          afterFirst,
          _ordersToTriggerProcessWork(),
        );
        expect(afterSecond.worldState.tileState.improvementLevel(tileKey), 1);
      },
    );

    test('explore completion sets visibility and clears currentWork', () {
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: 'explore',
          tileKey: tileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
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
              provinceId: [tileKey],
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
      expect(
        next.worldState.playerVisibilityByTile['p1']?[tileKey],
        VisibilityLevel.fullyVisible.name,
      );
    });

    test('build_road completion increases road level', () {
      final tileState = TileMapState().setRoadLevel(tileKey, 0);
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: 'build_road',
          tileKey: tileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
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
          tileState: tileState,
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final next = applyBuildAndWorkOrders(
        game,
        _ordersToTriggerProcessWork(),
        tileMapByRegion: const {},
      );
      expect(next.worldState.tileState.roadLevel(tileKey), 1);
    });

    test(
      'build_road completion propagates transport level to adjacent capital tile (no downgrade)',
      () {
        const capitalTileKey = 'oldWorld|P1|1|0';
        final initialTileState = TileMapState()
            .setRoadLevel(tileKey, 0)
            .setRoadLevel(capitalTileKey, 2);
        final unit = Unit(
          id: 'u1',
          type: 'Engineer',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: 'build_road',
            tileKey: tileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
        );
        final player = Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
          capitalProvinceId: provinceId,
          capitalTile: const CapitalTile(
            regionId: ow,
            provinceId: provinceId,
            x: 1,
            y: 0,
          ),
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
            tileState: initialTileState,
          ),
          players: [player],
        );
        final next = applyBuildAndWorkOrders(
          game,
          _ordersToTriggerProcessWork(),
          tileMapByRegion: {ow: _simpleTileMap()},
        );

        // Road built on target tile.
        expect(next.worldState.tileState.roadLevel(tileKey), 1);
        // Capital tile was already at level 2 and should remain 2 (no downgrade).
        expect(next.worldState.tileState.roadLevel(capitalTileKey), 2);
      },
    );

    test(
      'build_road completion propagates transport level to adjacent port tile and upgrades it',
      () {
        const portTileKey = 'oldWorld|P1|1|0';
        final initialTileState = TileMapState()
            .setRoadLevel(tileKey, 1)
            .setRoadLevel(portTileKey, 1);
        final unit = Unit(
          id: 'u1',
          type: 'Engineer',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: 'build_road',
            tileKey: tileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
        );
        final player = Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
          capitalProvinceId: provinceId,
          techUnlocked: const {'road_construction': true},
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileState: initialTileState,
          portsByProvinceSeaboard: const {'$provinceId|sea1': portTileKey},
        );
        final game = Game(id: 'g', worldState: world, players: [player]);

        final next = applyBuildAndWorkOrders(
          game,
          _ordersToTriggerProcessWork(),
          tileMapByRegion: {ow: _simpleTileMap()},
        );

        // Road on target tile upgraded from 1 -> 2.
        expect(next.worldState.tileState.roadLevel(tileKey), 2);
        // Adjacent port tile upgraded from 1 -> 2.
        expect(next.worldState.tileState.roadLevel(portTileKey), 2);
      },
    );

    test(
      'build_port completion sets port and road level 4 when topology has sea',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
        );
        final unit = Unit(
          id: 'u1',
          type: 'Engineer',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: 'build_port',
            tileKey: tileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
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
        final next = applyBuildAndWorkOrders(
          game,
          _ordersToTriggerProcessWork(),
          topology: topology,
        );
        expect(next.worldState.tileState.roadLevel(tileKey), 4);
        expect(
          next.worldState.portsByProvinceSeaboard.keys.any(
            (k) => k.startsWith(provinceId),
          ),
          isTrue,
        );
      },
    );

    test('build_fort completion increases province fortLevel', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: 'build_fort',
          tileKey: tileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
      );
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
                fortLevel: 0,
              ),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
      expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
    });

    test('build_rail completion leaves road when tile has no road', () {
      final tileState = TileMapState().setRoadLevel(tileKey, 0);
      final unit = Unit(
        id: 'u1',
        type: 'Rail Builder',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: 'build_rail',
          tileKey: tileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
      );
      final railMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P1'],
        ],
        terrainGrid: [
          [TerrainType.plains],
        ],
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
          tileState: tileState,
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            techUnlocked: const {'early_steam_engine': true},
          ),
        ],
      );
      final next = applyBuildAndWorkOrders(
        game,
        _ordersToTriggerProcessWork(),
        tileMapByRegion: {ow: railMap},
      );
      expect(next.worldState.tileState.roadLevel(tileKey), 0);
    });

    test('build_rail completion sets road level to 4 when valid', () {
      final tileState = TileMapState().setRoadLevel(tileKey, 1);
      final unit = Unit(
        id: 'u1',
        type: 'Rail Builder',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: 'build_rail',
          tileKey: tileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
      );
      final railMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P1'],
        ],
        terrainGrid: [
          [TerrainType.plains],
        ],
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
          tileState: tileState,
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            techUnlocked: const {'early_steam_engine': true},
          ),
        ],
      );
      final next = applyBuildAndWorkOrders(
        game,
        _ordersToTriggerProcessWork(),
        tileMapByRegion: {ow: railMap},
      );
      expect(next.worldState.tileState.roadLevel(tileKey), 4);
    });
  });

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

    test('unknown work target is skipped and unit stays idle', () {
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
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
              target: 'unknown_target',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final u = next.worldState.oldWorld.units.single;
      expect(u.status, UnitStatus.idle);
      expect(u.currentWork, isNull);
    });

    test('counter_spy work order sets currentWork for Spy unit', () {
      final unit = Unit(
        id: 'spy1',
        type: 'Spy',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p2')],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'spy1',
              target: 'counter_spy',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final spyAfter = next.worldState.oldWorld.units.single;
      expect(spyAfter.currentWork, isNotNull);
      expect(spyAfter.currentWork!.workTarget, 'counter_spy');
      expect(spyAfter.currentWork!.totalTurns, 0);
      expect(spyAfter.currentWork!.remainingTurns, 1);
    });

    test(
      'purchase_land success: treasury deducted and tile recorded in purchasedTilesByTileKey',
      () {
        const minorProvinceId = 'oldWorld|M1';
        const tileKeyMinor = 'oldWorld|M1|0|0';
        const cost = 15 * 10; // grain base price 10
        final unit = Unit(
          id: 'merchant1',
          type: 'Merchant',
          ownerId: 'p1',
          locationProvinceId: minorProvinceId,
          tileKey: tileKeyMinor,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKeyMinor: 'grain'},
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
                minorProvinceId: [tileKeyMinor],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              treasury: cost + 100,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], 'p1');
        expect(
          next.players.single.treasury,
          game.players.single.treasury - cost,
        );
      },
    );

    test(
      'purchase_land rejected when no Embassy with province owner (Minor/Tribe)',
      () {
        const minorProvinceId = 'oldWorld|M1';
        const tileKeyMinor = 'oldWorld|M1|0|0';
        const cost = 15 * 10; // grain base price 10
        final unit = Unit(
          id: 'merchant1',
          type: 'Merchant',
          ownerId: 'p1',
          locationProvinceId: minorProvinceId,
          tileKey: tileKeyMinor,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKeyMinor: 'grain'},
            tileKeysByRegionAndProvince: const {
              ow: {
                provinceId: [tileKey],
                minorProvinceId: [tileKeyMinor],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              treasury: cost + 100,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          // No overtureStates → no Embassy with province owner.
          overtureStates: const [],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], isNull);
        expect(next.players.single.treasury, game.players.single.treasury);
      },
    );

    test(
      'purchase_land rejected when at war with province owner (Minor/Tribe)',
      () {
        const minorProvinceId = 'oldWorld|M1';
        const tileKeyMinor = 'oldWorld|M1|0|0';
        const cost = 15 * 10; // grain base price 10
        final unit = Unit(
          id: 'merchant1',
          type: 'Merchant',
          ownerId: 'p1',
          locationProvinceId: minorProvinceId,
          tileKey: tileKeyMinor,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKeyMinor: 'grain'},
            tileKeysByRegionAndProvince: const {
              ow: {
                provinceId: [tileKey],
                minorProvinceId: [tileKeyMinor],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              treasury: cost + 100,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'minor1',
              state: RelationState.atWar,
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], isNull);
        expect(next.players.single.treasury, game.players.single.treasury);
      },
    );

    test(
      'purchase_land same tile by two GPs: first wins, second does not deduct or overwrite',
      () {
        const minorProvinceId = 'oldWorld|M1';
        const tileKeyMinor = 'oldWorld|M1|0|0';
        const cost = 15 * 10; // grain base price 10
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [
                Unit(
                  id: 'merchant1',
                  type: 'Merchant',
                  ownerId: 'p1',
                  locationProvinceId: minorProvinceId,
                  tileKey: tileKeyMinor,
                ),
                Unit(
                  id: 'merchant2',
                  type: 'Merchant',
                  ownerId: 'p2',
                  locationProvinceId: minorProvinceId,
                  tileKey: tileKeyMinor,
                ),
              ],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKeyMinor: 'grain'},
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
                minorProvinceId: [tileKeyMinor],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              treasury: cost + 100,
              capitalProvinceId: provinceId,
            ),
            Player(
              id: 'p2',
              displayName: 'P2',
              isHuman: false,
              treasury: cost + 100,
              capitalProvinceId: provinceId,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
            OvertureState(
              gpId: 'p2',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
            'p2': [
              const WorkOrder(
                unitId: 'merchant2',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], 'p1');
        final p1After = next.playerById('p1')!;
        final p2After = next.playerById('p2')!;
        expect(p1After.treasury, game.playerById('p1')!.treasury - cost);
        expect(p2After.treasury, game.playerById('p2')!.treasury);
      },
    );

    test(
      'build_road with insufficient materials does not set currentWork or deduct stockpile',
      () {
        final unit = Unit(
          id: 'u1',
          type: 'Engineer',
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
          players: [
            const Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: Stockpile(),
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
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
        expect(
          next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),
          0,
        );
      },
    );

    test(
      'build_road with sufficient materials deducts materials and sets currentWork',
      () {
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
        for (final e in cost.entries) {
          expect(
            next.players.single.stockpile.quantityOf(e.key),
            game.players.single.stockpile.quantityOf(e.key) - e.value,
          );
        }
      },
    );

    test('build_fort with sufficient materials deducts materials', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final cost = workOrderCostBuildFort(0);
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
                fortLevel: 0,
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
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'build_fort',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      for (final e in cost.entries) {
        expect(
          next.players.single.stockpile.quantityOf(e.key),
          game.players.single.stockpile.quantityOf(e.key) - e.value,
        );
      }
    });

    test('build_fort to level 2 is skipped without Mine Engineering', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
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
          const Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            techUnlocked: {},
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'build_fort',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
      expect(next.worldState.oldWorld.units.single.currentWork, isNull);
    });

    test('build_fort to level 3 is skipped without Modern Forts', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
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
              Province(
                id: provinceId,
                regionId: ow,
                ownerId: 'p1',
                fortLevel: 2,
              ),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            techUnlocked: {'mine_engineering': true},
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'build_fort',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.provinces.single.fortLevel, 2);
      expect(next.worldState.oldWorld.units.single.currentWork, isNull);
    });

    test('upgrade_town completion increases province townDevelopmentLevel', () {
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: 'upgrade_town',
          tileKey: tileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
      );
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
                townDevelopmentLevel: 1,
              ),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final next = applyBuildAndWorkOrders(
        game,
        Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]}),
      );
      expect(next.worldState.oldWorld.provinces.single.townDevelopmentLevel, 2);
    });

    test(
      'steal_tech completion clears currentWork after remainingTurns reach zero',
      () {
        const p2Capital = 'oldWorld|P2';
        const capTileKey = 'oldWorld|P2|0|0';
        final spy = Unit(
          id: 'spy1',
          type: 'Spy',
          ownerId: 'p1',
          locationProvinceId: p2Capital,
          tileKey: capTileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: 'steal_tech',
            tileKey: capTileKey,
            totalTurns: 5,
            remainingTurns: 1,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: p2Capital, regionId: ow, ownerId: 'p2'),
              ],
              units: [spy],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
                p2Capital: [capTileKey],
              },
            },
          ),
          players: [
            const Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: 'oldWorld|P1',
            ),
            Player(
              id: 'p2',
              displayName: 'P2',
              isHuman: true,
              capitalProvinceId: p2Capital,
              techUnlocked: {'some_tech': true},
            ),
          ],
        );
        final next = applyBuildAndWorkOrders(
          game,
          Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]}),
        );
        final spyAfter = next.worldState.oldWorld.units.single;
        expect(spyAfter.id, 'spy1');
        expect(spyAfter.ownerId, 'p1');
      },
    );

    test(
      'counter_spy processWork runs and may remove enemy Spy in same province',
      () {
        const provId = 'oldWorld|P1';
        const tileKeyP1 = 'oldWorld|P1|0|0';
        final p1Spy = Unit(
          id: 'spy1',
          type: 'Spy',
          ownerId: 'p1',
          locationProvinceId: provId,
          tileKey: tileKeyP1,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: 'counter_spy',
            tileKey: tileKeyP1,
            totalTurns: 0,
            remainingTurns: 1,
          ),
        );
        final p2Spy = Unit(
          id: 'spy2',
          type: 'Spy',
          ownerId: 'p2',
          locationProvinceId: provId,
          tileKey: tileKeyP1,
        );
        final game = Game(
          id: 'g',
          globalGameSeed: 12345,
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [Province(id: provId, regionId: ow, ownerId: 'p1')],
              units: [p1Spy, p2Spy],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provId: [tileKeyP1],
              },
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: true),
          ],
        );
        final next = applyBuildAndWorkOrders(
          game,
          Orders(
            buildUnitOrdersByPlayerId: {
              'p1': <BuildUnitOrder>[],
              'p2': <BuildUnitOrder>[],
            },
          ),
        );
        final units = next.worldState.oldWorld.units;
        expect(units.any((u) => u.id == 'spy1'), isTrue);
        expect(units.length, lessThanOrEqualTo(2));
      },
    );
  });

  group('applyBuildAndWorkOrders military and ship skip branches', () {
    test('skips build when unitType unknown in RegimentEconomyCatalog', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: Stockpile(),
            workerPool: WorkerPool(peasants: 5),
            treasury: 1000,
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'unknown_regiment_xyz',
              isMilitary:
                  buildUnitCategoryForUnitType('unknown_regiment_xyz') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
    });

    test('skips military build when zero peasants', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: stockpile,
            workerPool: const WorkerPool(peasants: 0),
            treasury: econ.buildTreasuryCost + 10,
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary:
                  buildUnitCategoryForUnitType('peasant_levies') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
    });

    test('skips military build when tech not unlocked', () {
      final regimentWithTech = unlockingTechByRegimentId.keys.firstOrNull;
      if (regimentWithTech == null) return; // no regiment with tech in catalog
      final econ = RegimentEconomyCatalog.byId[regimentWithTech];
      if (econ == null) return;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: stockpile,
            workerPool: const WorkerPool(peasants: 3),
            treasury: econ.buildTreasuryCost + 10,
            techUnlocked: {}, // none unlocked
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: regimentWithTech,
              isMilitary:
                  buildUnitCategoryForUnitType(regimentWithTech) ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
    });

    test('skips ship build when tech not unlocked', () {
      const shipTypeId = 'fluyte';
      final shipEcon = ShipEconomyCatalog.byId[shipTypeId];
      if (shipEcon == null || unlockingTechByShipId[shipTypeId] == null) return;
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
      );
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|P1',
            stockpile: stockpile,
            treasury: shipEcon.buildTreasuryCost + 10,
            techUnlocked: {}, // fluyte requires superior_hull_design
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: shipTypeId,
              isMilitary:
                  buildUnitCategoryForUnitType(shipTypeId) ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      expect(next.worldState.fleets, isEmpty);
    });

    test('ship build with topology null does not add fleet', () {
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: 'oldWorld|P1',
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 0),
        treasury: shipEcon.buildTreasuryCost + 10,
        techUnlocked: {'superior_hull_design': true},
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'fluyte',
              isMilitary:
                  buildUnitCategoryForUnitType('fluyte') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders); // no topology
      expect(next.worldState.fleets, isEmpty);
    });

    test('ship build with capitalProvinceId null does not add fleet', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
      );
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: null, // no capital
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 0),
        treasury: shipEcon.buildTreasuryCost + 10,
        techUnlocked: {'superior_hull_design': true},
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'fluyte',
              isMilitary:
                  buildUnitCategoryForUnitType('fluyte') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      expect(next.worldState.fleets, isEmpty);
    });

    test('ship build with capital not adjacent to sea does not add ship', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [], // P1 not connected to sea
      );
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: 'oldWorld|P1',
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 0),
        treasury: shipEcon.buildTreasuryCost + 10,
        techUnlocked: {'superior_hull_design': true},
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'fluyte',
              isMilitary:
                  buildUnitCategoryForUnitType('fluyte') ==
                  BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      expect(next.worldState.fleets, isEmpty);
    });
  });

  group('applyBuildAndWorkOrders civilian and New World spawn', () {
    test(
      'civilian spawn gets firstTileInSpawn when tileKeysByRegionAndProvince has tile',
      () {
        const ow = 'oldWorld';
        const provinceId = 'oldWorld|P1';
        const firstTile = 'oldWorld|P1|0|0';
        final explorerEcon = CivilianEconomyCatalog.byId['Explorer']!;
        var stockpile = const Stockpile();
        for (final e in explorerEcon.buildInputs.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value + 1);
        }
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [firstTile, 'oldWorld|P1|1|0'],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              stockpile: stockpile,
              workerPool: const WorkerPool(peasants: 1),
              treasury: explorerEcon.buildTreasuryCost + 100,
            ),
          ],
        );
        final orders = Orders(
          buildUnitOrdersByPlayerId: {
            'p1': [
              BuildUnitOrder(
                unitType: 'Explorer',
                isMilitary:
                    buildUnitCategoryForUnitType('Explorer') ==
                    BuildUnitCategory.military,
                spawnProvinceId: provinceId,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.oldWorld.units.length, 1);
        expect(next.worldState.oldWorld.units.single.tileKey, firstTile);
      },
    );

    test('civilian build with empty spawnProvinceId falls back to capital', () {
      const ow = 'oldWorld';
      const capitalProvinceId = 'oldWorld|P1';
      const firstTile = 'oldWorld|P1|0|0';
      final explorerEcon = CivilianEconomyCatalog.byId['Explorer']!;
      var stockpile = const Stockpile();
      for (final e in explorerEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: capitalProvinceId, regionId: ow, ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              capitalProvinceId: [firstTile],
            },
          },
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: capitalProvinceId,
            stockpile: stockpile,
            treasury: explorerEcon.buildTreasuryCost + 100,
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Explorer',
              isMilitary: false,
              spawnProvinceId: '',
            ),
          ],
        },
      );

      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units.length, 1);
      expect(
        next.worldState.oldWorld.units.single.locationProvinceId,
        capitalProvinceId,
      );
      expect(next.worldState.oldWorld.units.single.tileKey, firstTile);
    });

    test(
      'civilian build with foreign spawnProvinceId falls back to capital',
      () {
        const ow = 'oldWorld';
        const capitalProvinceId = 'oldWorld|P1';
        const foreignProvinceId = 'oldWorld|P2';
        const firstTile = 'oldWorld|P1|0|0';
        final explorerEcon = CivilianEconomyCatalog.byId['Explorer']!;
        var stockpile = const Stockpile();
        for (final e in explorerEcon.buildInputs.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value + 1);
        }
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: capitalProvinceId, regionId: ow, ownerId: 'p1'),
                Province(id: foreignProvinceId, regionId: ow, ownerId: 'p2'),
              ],
              units: [],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                capitalProvinceId: [firstTile],
                foreignProvinceId: ['oldWorld|P2|0|0'],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: capitalProvinceId,
              stockpile: stockpile,
              treasury: explorerEcon.buildTreasuryCost + 100,
            ),
          ],
        );
        final orders = Orders(
          buildUnitOrdersByPlayerId: {
            'p1': [
              BuildUnitOrder(
                unitType: 'Explorer',
                isMilitary: false,
                spawnProvinceId: foreignProvinceId,
              ),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.oldWorld.units.length, 1);
        expect(
          next.worldState.oldWorld.units.single.locationProvinceId,
          capitalProvinceId,
        );
        expect(next.worldState.oldWorld.units.single.tileKey, firstTile);
      },
    );

    test('New World spawn adds unit to newWorld', () {
      const nw = 'newWorld';
      const provinceId = 'newWorld|N1';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: nw, ownerId: 'p1')],
            units: [],
          ),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: provinceId,
            stockpile: Stockpile(),
            workerPool: WorkerPool(peasants: 1),
            treasury: 500,
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary:
                  buildUnitCategoryForUnitType('peasant_levies') ==
                  BuildUnitCategory.military,
              spawnProvinceId: provinceId,
            ),
          ],
        },
      );
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final gameWithStock = game.copyWith(
        players: [
          game.players.single.copyWith(
            stockpile: stockpile,
            treasury: econ.buildTreasuryCost + 10,
          ),
        ],
      );
      final next = applyBuildAndWorkOrders(gameWithStock, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.worldState.newWorld.units.length, 1);
      expect(
        next.worldState.newWorld.units.single.locationProvinceId,
        provinceId,
      );
    });
  });

  group('clearUnitCurrentWork', () {
    test('returns game unchanged when unit has no currentWork', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
      );
      final result = clearUnitCurrentWork(game, 'u1');
      expect(identical(result, game), isTrue);
    });

    test(
      'clears currentWork and sets status idle when unit has currentWork',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p1|0|0',
          status: UnitStatus.working,
          currentWork: CurrentWork(
            workTarget: 'build_improvement',
            tileKey: 'oldWorld|p1|0|0',
            totalTurns: 2,
            remainingTurns: 1,
          ),
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
          ),
          players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
        );
        final result = clearUnitCurrentWork(game, 'u1');
        expect(result.worldState.oldWorld.units.length, 1);
        expect(result.worldState.oldWorld.units.single.currentWork, isNull);
        expect(result.worldState.oldWorld.units.single.status, UnitStatus.idle);
      },
    );
  });
}
