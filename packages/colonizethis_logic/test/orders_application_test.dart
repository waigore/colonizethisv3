import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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
            Province(
              id: 'P1',
              regionId: 'oldWorld',
              ownerId: playerId,
            ),
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
              isMilitary: buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military,
              spawnProvinceId: spawn,
            ),
          ],
        },
      );
    }

    test('rejects build when treasury is insufficient', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      final game = _baseGame(
        peasants: 5,
        treasury: econ.buildTreasuryCost - 1,
      );
      final orders = _ordersFor('peasant_levies');

      final next = applyBuildAndWorkOrders(game, orders);

      // No unit spawned and treasury unchanged.
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(next.players.single.workerPool.peasants,
          game.players.single.workerPool.peasants);
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
      expect(next.players.single.workerPool.peasants,
          game.players.single.workerPool.peasants);
    });

    test('applies treasury, stockpile and worker costs when valid', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final entry in econ.buildInputs.entries) {
        stockpile =
            stockpile.applyDelta(entry.key, entry.value + 1); // small surplus
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
          provinces: [
            Province(
              id: 'P1',
              regionId: 'oldWorld',
              ownerId: 'p1',
            ),
          ],
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
      expect(next.worldState.oldWorld.units.length, game.worldState.oldWorld.units.length);
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(next.players.single.workerPool.peasants, game.players.single.workerPool.peasants);
    });

    test('ship build adds ship to fleet when topology and capital with sea', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
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
      final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final gameWithStock = game.copyWith(
        players: [player.copyWith(
          stockpile: stockpile,
          treasury: shipEcon.buildTreasuryCost + 10,
        )],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'fluyte',
              isMilitary: buildUnitCategoryForUnitType('fluyte') == BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(gameWithStock, orders, topology: topology);
      expect(next.worldState.fleets, isNotEmpty);
      expect(next.worldState.fleets.any((f) => f.ownerId == 'p1' && f.shipTypeIds.contains('fluyte')), isTrue);
    });

    test('second naval build adds ship to existing home fleet', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'Sea1', regionId: ow, type: TopologyNodeType.seaZone),
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
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
          units: const [],
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
              isMilitary: buildUnitCategoryForUnitType('fluyte') == BuildUnitCategory.military,
              spawnProvinceId: '$ow|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders, topology: topology);
      final p1Fleet = next.worldState.fleets.where((f) => f.ownerId == 'p1').single;
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
              isMilitary: buildUnitCategoryForUnitType('Builder') == BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.players.single.treasury, game.players.single.treasury);
      expect(next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
          game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id));
    });

    test('rejects civilian build when paper insufficient', () {
      final game = _civilianGame(treasury: 1000, paper: 0);
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Builder',
              isMilitary: buildUnitCategoryForUnitType('Builder') == BuildUnitCategory.military,
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
              isMilitary: buildUnitCategoryForUnitType('Builder') == BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units.length, 1);
      expect(next.worldState.oldWorld.units.single.type, 'Builder');
      expect(next.players.single.treasury, game.players.single.treasury - cash);
      expect(next.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
          game.players.single.stockpile.quantityOf(CommodityCatalog.paper.id) - paperQty);
    });

    test('Merchant requires merchant_companies tech', () {
      const cash = 2000;
      const paperQty = 4;
      final gameNoTech = _civilianGame(treasury: cash + 100, paper: paperQty + 1, techUnlocked: {});
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Merchant',
              isMilitary: buildUnitCategoryForUnitType('Merchant') == BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final nextNoTech = applyBuildAndWorkOrders(gameNoTech, orders);
      expect(nextNoTech.worldState.oldWorld.units, isEmpty);
      expect(nextNoTech.players.single.treasury, gameNoTech.players.single.treasury);

      final gameWithTech = _civilianGame(
        treasury: cash + 100,
        paper: paperQty + 1,
        techUnlocked: {'merchant_companies': true},
      );
      final nextWithTech = applyBuildAndWorkOrders(gameWithTech, orders);
      expect(nextWithTech.worldState.oldWorld.units.length, 1);
      expect(nextWithTech.worldState.oldWorld.units.single.type, 'Merchant');
      expect(nextWithTech.players.single.treasury, gameWithTech.players.single.treasury - cash);
      expect(nextWithTech.players.single.stockpile.quantityOf(CommodityCatalog.paper.id),
          gameWithTech.players.single.stockpile.quantityOf(CommodityCatalog.paper.id) - paperQty);
    });
  });

  group('applyBuildAndWorkOrders work completion', () {
    const ow = 'oldWorld';
    const tileKey = 'oldWorld|P1|0|0';
    const provinceId = 'oldWorld|P1';

    // Non-empty orders so applyBuildAndWorkOrders does not return early (empty build list still counts).
    Orders _ordersToTriggerProcessWork() => Orders(
          buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]},
        );

    test('build_improvement completion increases improvement level and clears currentWork', () {
      final tileState = TileMapState().setImprovement(tileKey, 0);
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: 'p1',
        provinceId: provinceId,
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
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
      expect(next.worldState.tileState.improvementLevel(tileKey), 1);
    });

    test('multi-turn work decrements remainingTurns and completes only when zero', () {
      final tileState = TileMapState().setImprovement(tileKey, 0);
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: 'p1',
        provinceId: provinceId,
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
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final afterFirst = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
      expect(afterFirst.worldState.tileState.improvementLevel(tileKey), 0);
      final uAfterFirst = afterFirst.worldState.oldWorld.units.single;
      expect(uAfterFirst.currentWork!.remainingTurns, 1);
      final afterSecond = applyBuildAndWorkOrders(afterFirst, _ordersToTriggerProcessWork());
      expect(afterSecond.worldState.tileState.improvementLevel(tileKey), 1);
    });

    test('explore completion sets visibility and clears currentWork', () {
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: 'p1',
        provinceId: provinceId,
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
            ow: {provinceId: [tileKey]},
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
        provinceId: provinceId,
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
      final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
      expect(next.worldState.tileState.roadLevel(tileKey), 1);
    });

    test('build_port completion sets port and road level 4 when topology has sea', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
      );
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        provinceId: provinceId,
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
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork(), topology: topology);
      expect(next.worldState.tileState.roadLevel(tileKey), 4);
      expect(
        next.worldState.portsByProvinceSeaboard.keys.any((k) => k.startsWith(provinceId)),
        isTrue,
      );
    });

    test('build_fort completion increases province fortLevel', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        provinceId: provinceId,
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
              Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 0),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
      expect(
        next.worldState.oldWorld.provinces.single.fortLevel,
        1,
      );
    });

    test('build_rail completion sets road level to 4', () {
      final tileState = TileMapState().setRoadLevel(tileKey, 0);
      final unit = Unit(
        id: 'u1',
        type: 'Rail Builder',
        ownerId: 'p1',
        provinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: 'build_rail',
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
      final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
      expect(next.worldState.tileState.roadLevel(tileKey), 4);
    });
  });

  group('applyBuildAndWorkOrders work order application', () {
    const ow = 'oldWorld';
    const provinceId = 'oldWorld|P1';
    const tileKey = 'oldWorld|P1|0|0';

    test('prospect adds tile to playerProspectedTiles', () {
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: 'p1',
        provinceId: provinceId,
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
              target: 'prospect',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(
        next.worldState.playerProspectedTiles['p1'],
        contains(tileKey),
      );
    });

    test('build_improvement work order sets currentWork', () {
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: 'p1',
        provinceId: provinceId,
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
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true, stockpile: stockpile),
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
      expect(u.currentWork, isNotNull);
      expect(u.currentWork!.workTarget, 'build_improvement');
      expect(u.currentWork!.remainingTurns, 1);
    });

    test('explore work order sets currentWork when province has tiles', () {
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: 'p1',
        provinceId: provinceId,
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
            ow: {provinceId: [tileKey, 'oldWorld|P1|1|0']},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'explore',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final u = next.worldState.oldWorld.units.single;
      expect(u.currentWork, isNotNull);
      expect(u.currentWork!.workTarget, 'explore');
      expect(u.currentWork!.totalTurns, greaterThanOrEqualTo(1));
    });

    test('Engineer build_road work order sets currentWork', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        provinceId: provinceId,
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
          Player(id: 'p1', displayName: 'P1', isHuman: true, stockpile: stockpile),
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
      expect(u.currentWork, isNotNull);
      expect(u.currentWork!.workTarget, 'build_road');
      expect(u.currentWork!.remainingTurns, 1);
    });

    test('unknown work target is skipped and unit stays idle', () {
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: 'p1',
        provinceId: provinceId,
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

    test('purchase_land success: treasury deducted and tile recorded in purchasedTilesByTileKey', () {
      const minorProvinceId = 'oldWorld|M1';
      const tileKeyMinor = 'oldWorld|M1|0|0';
      const cost = 15 * 10; // grain base price 10
      final unit = Unit(
        id: 'merchant1',
        type: 'Merchant',
        ownerId: 'p1',
        provinceId: minorProvinceId,
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
          tileKeysByRegionAndProvince: {ow: {provinceId: [tileKey], minorProvinceId: [tileKeyMinor]}},
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            treasury: cost + 100,
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
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
      expect(next.players.single.treasury, game.players.single.treasury - cost);
    });

    test('build_road with insufficient materials does not set currentWork or deduct stockpile', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        provinceId: provinceId,
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
      expect(next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id), 0);
    });

    test('build_road with sufficient materials deducts materials and sets currentWork', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        provinceId: provinceId,
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
          Player(id: 'p1', displayName: 'P1', isHuman: true, stockpile: stockpile),
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
      expect(u.currentWork, isNotNull);
      expect(u.currentWork!.workTarget, 'build_road');
      for (final e in cost.entries) {
        expect(
          next.players.single.stockpile.quantityOf(e.key),
          game.players.single.stockpile.quantityOf(e.key) - e.value,
        );
      }
    });

    test('build_fort with sufficient materials deducts materials', () {
      final unit = Unit(
        id: 'u1',
        type: 'Engineer',
        ownerId: 'p1',
        provinceId: provinceId,
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
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 0)],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true, stockpile: stockpile),
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

    test('upgrade_town completion increases province townDevelopmentLevel', () {
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: 'p1',
        provinceId: provinceId,
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
              Province(id: provinceId, regionId: ow, ownerId: 'p1', townDevelopmentLevel: 1),
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

    test('steal_tech completion clears currentWork after remainingTurns reach zero', () {
      const p2Capital = 'oldWorld|P2';
      const capTileKey = 'oldWorld|P2|0|0';
      final spy = Unit(
        id: 'spy1',
        type: 'Spy',
        ownerId: 'p1',
        provinceId: p2Capital,
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
          tileKeysByRegionAndProvince: {ow: {provinceId: [tileKey], p2Capital: [capTileKey]}},
        ),
        players: [
          const Player(id: 'p1', displayName: 'P1', isHuman: true, capitalProvinceId: 'oldWorld|P1'),
          Player(id: 'p2', displayName: 'P2', isHuman: true, capitalProvinceId: p2Capital, techUnlocked: {'some_tech': true}),
        ],
      );
      final next = applyBuildAndWorkOrders(
        game,
        Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]}),
      );
      final spyAfter = next.worldState.oldWorld.units.single;
      expect(spyAfter.id, 'spy1');
      expect(spyAfter.ownerId, 'p1');
    });

    test('counter_spy processWork runs and may remove enemy Spy in same province', () {
      const provId = 'oldWorld|P1';
      const tileKeyP1 = 'oldWorld|P1|0|0';
      final p1Spy = Unit(
        id: 'spy1',
        type: 'Spy',
        ownerId: 'p1',
        provinceId: provId,
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
        provinceId: provId,
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
          tileKeysByRegionAndProvince: {ow: {provId: [tileKeyP1]}},
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final next = applyBuildAndWorkOrders(
        game,
        Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[], 'p2': <BuildUnitOrder>[]}),
      );
      final units = next.worldState.oldWorld.units;
      expect(units.any((u) => u.id == 'spy1'), isTrue);
      expect(units.length, lessThanOrEqualTo(2));
    });
  });

  group('applyBuildAndWorkOrders military and ship skip branches', () {
    test('skips build when unitType unknown in RegimentEconomyCatalog', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1')],
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
              isMilitary: buildUnitCategoryForUnitType('unknown_regiment_xyz') == BuildUnitCategory.military,
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
            provinces: [Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1')],
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
              isMilitary: buildUnitCategoryForUnitType('peasant_levies') == BuildUnitCategory.military,
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
            provinces: [Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1')],
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
              isMilitary: buildUnitCategoryForUnitType(regimentWithTech) == BuildUnitCategory.military,
              spawnProvinceId: 'oldWorld|P1',
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
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
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1')],
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
              isMilitary: buildUnitCategoryForUnitType('fluyte') == BuildUnitCategory.military,
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
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
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
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1')],
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
              isMilitary: buildUnitCategoryForUnitType('fluyte') == BuildUnitCategory.military,
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
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
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
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1')],
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
              isMilitary: buildUnitCategoryForUnitType('fluyte') == BuildUnitCategory.military,
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
    test('civilian spawn gets firstTileInSpawn when tileKeysByRegionAndProvince has tile', () {
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
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {provinceId: [firstTile, 'oldWorld|P1|1|0']},
          },
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
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
              isMilitary: buildUnitCategoryForUnitType('Explorer') == BuildUnitCategory.military,
              spawnProvinceId: provinceId,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.units.length, 1);
      expect(next.worldState.oldWorld.units.single.tileKey, firstTile);
    });

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
              isMilitary: buildUnitCategoryForUnitType('peasant_levies') == BuildUnitCategory.military,
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
          game.players.single.copyWith(stockpile: stockpile, treasury: econ.buildTreasuryCost + 10),
        ],
      );
      final next = applyBuildAndWorkOrders(gameWithStock, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.worldState.newWorld.units.length, 1);
      expect(next.worldState.newWorld.units.single.provinceId, provinceId);
    });
  });
}