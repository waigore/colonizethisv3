import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders work completion', () {
    const ow = 'oldWorld';
    const tileKey = 'oldWorld|P1|0|0';
    const provinceId = 'oldWorld|P1';

    // Non-empty orders so applyBuildAndWorkOrders does not return early (empty build list still counts).
    Orders ordersToTriggerProcessWork() =>
        Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]});

    TileMapResult simpleTileMap() {
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
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
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
          ordersToTriggerProcessWork(),
        );
        expect(next.worldState.tileState.improvementLevel(tileKey), 1);
        final after = next.worldState.oldWorld.units.single;
        expect(after.tileKey, tileKey);
        expect(after.originTileKey, isNull);
        expect(after.assignedTileKey, isNull);
      },
    );

    test(
      'build_improvement completion sets envy mirror hint for human on extraction tile',
      () {
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
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
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKey: 'grain'},
            tileState: tileState,
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        expect(next.lastHumanCompletedResearchCategory, 'gathering');
        expect(next.lastHumanResearchCategoryCompletionTurn, 2);
      },
    );

    test(
      'build_improvement completion adds envy evidence when AI mirrors human gathering hint',
      () {
        const aiId = 'ai1';
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: aiId,
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
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
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: aiId),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKey: 'coal'},
            tileState: tileState,
          ),
          players: const [
            Player(id: 'human', displayName: 'H', isHuman: true),
            Player(id: aiId, displayName: 'AI', isHuman: false),
          ],
          aiControlByGpId: const {aiId: true},
          lastHumanCompletedResearchCategory: 'gathering',
          lastHumanResearchCategoryCompletionTurn: 0,
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        final envy = next.dossierEvidenceEntries
            .where((e) => e.agendaType == 'envy')
            .toList();
        expect(envy, isNotEmpty);
        expect(envy.single.subjectId, aiId);
        expect(envy.single.scoreDelta, 1);
      },
    );

    test(
      'build_improvement completion raises stored level from 3 to 4 (global max)',
      () {
        final tileState = TileMapState().setImprovement(tileKey, 3);
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
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
            resourceByTileKey: const {tileKey: 'grain'},
            tileState: tileState,
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        expect(next.worldState.tileState.improvementLevel(tileKey), 4);
      },
    );

    test(
      'build_improvement completion does not re-apply extraction tech cap (#1291)',
      () {
        // Assign-time would reject 3→4 with extraction cap 2; completion still applies +1 to stored level.
        expect(
          extractionCapForResourceForUnlocked(const {
            'saw_mill': true,
          }, 'grain'),
          1,
        );
        final tileState = TileMapState().setImprovement(tileKey, 3);
        final unit = Unit(
          id: 'u1',
          type: 'Builder',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
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
            resourceByTileKey: const {tileKey: 'grain'},
            tileState: tileState,
          ),
          players: const [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              techUnlocked: {'saw_mill': true},
            ),
          ],
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        expect(next.worldState.tileState.improvementLevel(tileKey), 4);
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
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
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
          ordersToTriggerProcessWork(),
        );
        final uAfter = next.worldState.oldWorld.units.single;
        expect(uAfter.status, UnitStatus.idle);
        expect(uAfter.currentWork, isNull);
        expect(uAfter.tileKey, 'oldWorld|P1|1|0');
        expect(uAfter.originTileKey, isNull);
        expect(uAfter.assignedTileKey, isNull);
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
          ordersToTriggerProcessWork(),
        );
        expect(afterFirst.worldState.tileState.improvementLevel(tileKey), 0);
        final uAfterFirst = afterFirst.worldState.oldWorld.units.single;
        expect(uAfterFirst.currentWork!.remainingTurns, 1);
        final afterSecond = applyBuildAndWorkOrders(
          afterFirst,
          ordersToTriggerProcessWork(),
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
      final next = applyBuildAndWorkOrders(game, ordersToTriggerProcessWork());
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
        ordersToTriggerProcessWork(),
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
          ordersToTriggerProcessWork(),
          tileMapByRegion: {ow: simpleTileMap()},
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
          ordersToTriggerProcessWork(),
          tileMapByRegion: {ow: simpleTileMap()},
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
          ordersToTriggerProcessWork(),
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
      final next = applyBuildAndWorkOrders(game, ordersToTriggerProcessWork());
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
        ordersToTriggerProcessWork(),
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
        ordersToTriggerProcessWork(),
        tileMapByRegion: {ow: railMap},
      );
      expect(next.worldState.tileState.roadLevel(tileKey), 4);
    });
  });
}
