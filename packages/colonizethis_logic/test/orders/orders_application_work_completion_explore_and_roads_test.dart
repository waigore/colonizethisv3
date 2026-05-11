import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';


void main() {
  group('applyBuildAndWorkOrders work completion (explore, roads, port)', () {
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

    test('explore completion sets visibility and clears currentWork', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetExplore,
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

    test(
      'explore completion reveals every tile in canonical full-id bucket',
      () {
        const tileKey2 = 'oldWorld|P1|1|0';
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetExplore,
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
            tileKeysByRegionAndProvince: const {
              ow: {
                provinceId: [tileKey, tileKey2],
                'P1': ['oldWorld|P1|9|9'],
              },
            },
            playerVisibilityByTile: const {
              'p1': {
                tileKey: 'fogged',
                tileKey2: 'unknown',
                'oldWorld|P1|9|9': 'unknown',
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        expect(
          next.worldState.playerVisibilityByTile['p1']?[tileKey],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          next.worldState.playerVisibilityByTile['p1']?[tileKey2],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          next.worldState.playerVisibilityByTile['p1']?['oldWorld|P1|9|9'],
          VisibilityLevel.unknown.name,
        );
      },
    );

    test('build_road completion increases road level', () {
      final tileState = TileMapState().setRoadLevel(tileKey, 0);
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildRoad,
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
          type: kUnitTypeEngineer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildRoad,
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
          type: kUnitTypeEngineer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildRoad,
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
          techUnlocked: const {kTechIdRoadConstruction: true},
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
  });
}
