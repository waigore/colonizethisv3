import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_orders/src/orders/orders_application_completed_work.dart';
import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('dispatchCompletedWorkTarget', () {
    const ow = 'oldWorld';
    const provinceId = 'oldWorld|P1';
    const tileKey = 'oldWorld|P1|0|0';

    test('routes kWorkTargetBuildRail through handler map entry', () {
      final tileState = TileMapState().setRoadLevel(tileKey, 1);
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeRailBuilder,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
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
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: provinceId, regionId: ow, ownerId: 'p1'),
            ],
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
            techUnlocked: const {kTechIdEarlySteamEngine: true},
          ),
        ],
      );
      final work = WorkOrderState(
        oldUnitsById: {unit.id: unit},
        newUnitsById: const {},
        tileState: tileState,
        visibilityByTile: const {},
        portsByProvinceSeaboard: const {},
        purchasedTilesByTileKey: const {},
        oldProvinces: game.worldState.oldWorld.provinces,
        newProvinces: const [],
      );
      final state = BuildWorkState(
        game: game,
        buildOrders: const {},
        workOrders: const {},
        tileMapByRegion: {ow: railMap},
        work: work,
      );
      const cw = CurrentWork(
        workTarget: kWorkTargetBuildRail,
        tileKey: tileKey,
        totalTurns: 1,
        remainingTurns: 0,
      );

      final next = dispatchCompletedWorkTarget(
        state,
        unit,
        cw,
        () => game.worldState.oldWorld.provinces,
        (w, p) => w.copyWith(oldProvinces: p),
        (s, u, regionId) => s,
      );

      expect(next.work.tileState.roadLevel(tileKey), 4);
    });

    test('build_rail completion no-ops when rejectionReasonForBuildRailOrder applies', () {
      final tileState = TileMapState().setRoadLevel(tileKey, 0);
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeRailBuilder,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
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
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: provinceId, regionId: ow, ownerId: 'p1'),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );
      final work = WorkOrderState(
        oldUnitsById: {unit.id: unit},
        newUnitsById: const {},
        tileState: tileState,
        visibilityByTile: const {},
        portsByProvinceSeaboard: const {},
        purchasedTilesByTileKey: const {},
        oldProvinces: game.worldState.oldWorld.provinces,
        newProvinces: const [],
      );
      final state = BuildWorkState(
        game: game,
        buildOrders: const {},
        workOrders: const {},
        tileMapByRegion: {ow: railMap},
        work: work,
      );
      const cw = CurrentWork(
        workTarget: kWorkTargetBuildRail,
        tileKey: tileKey,
        totalTurns: 1,
        remainingTurns: 0,
      );

      final next = dispatchCompletedWorkTarget(
        state,
        unit,
        cw,
        () => game.worldState.oldWorld.provinces,
        (w, p) => w.copyWith(oldProvinces: p),
        (s, u, regionId) => s,
      );

      expect(next.work.tileState.roadLevel(tileKey), 0);
    });

    test('upgrade_town threads getProvinces/replaceProvinces through the '
        'CompletedWorkContext record', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
      );
      const province = Province(
        id: provinceId,
        regionId: ow,
        ownerId: 'p1',
        townDevelopmentLevel: 0,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: const [province], units: [unit]),
          newWorld: const RegionData(),
          tileState: TileMapState(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final work = WorkOrderState(
        oldUnitsById: {unit.id: unit},
        newUnitsById: const {},
        tileState: TileMapState(),
        visibilityByTile: const {},
        portsByProvinceSeaboard: const {},
        purchasedTilesByTileKey: const {},
        oldProvinces: const [province],
        newProvinces: const [],
      );
      final state = BuildWorkState(
        game: game,
        buildOrders: const {},
        workOrders: const {},
        tileMapByRegion: const {},
        work: work,
      );
      const cw = CurrentWork(
        workTarget: kWorkTargetUpgradeTown,
        tileKey: tileKey,
        totalTurns: 1,
        remainingTurns: 0,
      );

      final next = dispatchCompletedWorkTarget(
        state,
        unit,
        cw,
        () => game.worldState.oldWorld.provinces,
        (w, p) => w.copyWith(oldProvinces: p),
        (s, u, regionId) => s,
      );

      expect(next.work.oldProvinces.single.townDevelopmentLevel, 1);
    });

    test('explore invokes the applyExploreCompletion closure with the unit '
        'region via the CompletedWorkContext record', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(units: [unit]),
          newWorld: const RegionData(),
          tileState: TileMapState(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final work = WorkOrderState(
        oldUnitsById: {unit.id: unit},
        newUnitsById: const {},
        tileState: TileMapState(),
        visibilityByTile: const {},
        portsByProvinceSeaboard: const {},
        purchasedTilesByTileKey: const {},
        oldProvinces: const [],
        newProvinces: const [],
      );
      final state = BuildWorkState(
        game: game,
        buildOrders: const {},
        workOrders: const {},
        tileMapByRegion: const {},
        work: work,
      );
      const cw = CurrentWork(
        workTarget: kWorkTargetExplore,
        tileKey: tileKey,
        totalTurns: 1,
        remainingTurns: 0,
      );

      String? capturedRegionId;
      final next = dispatchCompletedWorkTarget(
        state,
        unit,
        cw,
        () => game.worldState.oldWorld.provinces,
        (w, p) => w.copyWith(oldProvinces: p),
        (s, u, regionId) {
          capturedRegionId = regionId;
          return s;
        },
      );

      expect(capturedRegionId, ow);
      expect(identical(next, state), isTrue);
    });
  });
}
